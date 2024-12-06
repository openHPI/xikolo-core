# frozen_string_literal: true

# Keep the `on_demand_expires` next date in sync with the
# actual enrollment (booking state)
#
# The worker creates or updates the event if `on_demand` is
# booked for the enrollment. Otherwise such an next date
# is removed. All update and removal operations must be
# `user_id` limited: this type is always user-specific and
# the `slot_id` is static per course.
class NextDate::OnDemandExpiresSyncWorker
  include Sidekiq::Job

  def perform(course_id, user_id)
    @course_id = course_id
    @user_id = user_id

    return purge! unless applicable?

    NextDate
      .find_or_initialize_by(slot_id:, user_id: @user_id)
      .update(attrs)
  end

  private

  def enrollment
    @enrollment ||= Enrollment.active.find_by(course_id: @course_id,
      user_id: @user_id)
  end

  def applicable?
    enrollment&.forced_submission_date?
  end

  def purge!
    NextDate.where(slot_id:, user_id: @user_id).delete_all
  end

  def attrs
    {
      type: 'on_demand_expires',
      resource_type: 'on_demand',
      resource_id: @course_id,
      course_id: enrollment.course_id,
      date: enrollment.forced_submission_date,
      title: enrollment.course.title,
      section_pos: 0,
      item_pos: nil,
    }
  end

  def slot_id
    @slot_id ||= NextDate.calc_id(@course_id, 'on_demand_expires')
  end
end
