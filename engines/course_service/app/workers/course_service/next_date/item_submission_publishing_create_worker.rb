# frozen_string_literal: true

module CourseService
# Keep a user-specific `item_submission_publishing` next
# date in sync with the actual result/item
#
# The worker creates or updates a use-specific
# `item_submission_publishing` next date. It replaces the
# general `item_submission_deadline` next date.
# The next date is created even for items without
# `submission_publishing_date`, too. A dummy next date
# not visible at any time is created.
#
# The worker does not check whether the user still has an
# result as removal of results is not implemented at the
# moment.
class NextDate::ItemSubmissionPublishingCreateWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(item_id, user_id)
    @item_id = item_id
    @user_id = user_id

    return purge! unless applicable?

    CourseService::NextDate
      .find_or_initialize_by(slot_id:, user_id: @user_id)
      .update!(attrs)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  private

  def item
    return @item if defined?(@item)

    @item = Item.where(published: true).find_by(id: @item_id)
  end

  def applicable?
    item
  end

  def purge!
    NextDate.where(slot_id:, user_id: @user_id).delete_all
  end

  def attrs
    {
      type: 'item_submission_publishing',
      resource_type: 'item',
      resource_id: @item_id,
      course_id: item.section.course.id,
      # When there is no submission_publishing_date, we set a past
      # date to ensure the `item_submission_deadline` date is hidden
      # but the new date is excluded, too.
      date: item.submission_publishing_date || 1.second.ago,
      title: "#{item.section.title}: #{item.title}",
      section_pos: item.section.position,
      item_pos: item.position,
    }
  end

  def slot_id
    @slot_id ||= NextDate.calc_id(@item_id, 'item_submission')
  end
end
end
