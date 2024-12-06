# frozen_string_literal: true

# Keep the `course_start` next date in sync with the
# actual course (start)
#
# The worker creates or updates the event if a next date
# should be present for the course. Otherwise an existing
# next date resource is removed.
class NextDate::CourseStartSyncWorker
  include Sidekiq::Job

  def perform(course_id)
    @course_id = course_id

    return purge! unless applicable?

    NextDate
      .find_or_initialize_by(slot_id:)
      .update(attrs)
  end

  private

  def course
    @course ||= Course.find_by(id: @course_id)
  end

  def applicable?
    course && course[:status] != 'preparation' && date
  end

  def purge!
    NextDate.where(slot_id:).delete_all
  end

  def attrs
    {
      type: 'course_start',
      resource_type: 'course',
      resource_id: @course_id,
      course_id: @course_id,
      date:,
      title: course.title,
      section_pos: 0,
      item_pos: nil,
      visible_after: nil,
    }
  end

  def slot_id
    @slot_id ||= NextDate.calc_id(@course_id, 'course_start')
  end

  def date
    course.display_start_date || course.start_date
  end
end
