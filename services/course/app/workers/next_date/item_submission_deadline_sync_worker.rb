# frozen_string_literal: true

# Keep the `item_submission_deadline` next date in sync with
# the actual item (submission deadline).
#
# The worker creates or updates the event if a next date
# should be present for this item. Otherwise an existing
# next date and all overrides for users are removed.
class NextDate::ItemSubmissionDeadlineSyncWorker
  include Sidekiq::Job

  def perform(item_id)
    @item_id = item_id

    return purge! unless applicable?

    NextDate
      .find_or_initialize_by(slot_id:, user_id: NextDate.nil_user_id)
      .update!(attrs)
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  private

  def item
    @item ||= Item.where(published: true).find_by(id: @item_id)
  end

  def applicable?
    item&.submission_deadline?
  end

  def purge!
    NextDate.where(slot_id:).delete_all
  end

  def attrs
    {
      type: 'item_submission_deadline',
      resource_type: 'item',
      resource_id: @item_id,
      course_id: item.section.course.id,
      date: item.submission_deadline,
      title: "#{item.section.title}: #{item.title}",
      section_pos: item.section.position,
      item_pos: item.position,
      visible_after:,
    }
  end

  def slot_id
    @slot_id ||= NextDate.calc_id(@item_id, 'item_submission')
  end

  def visible_after
    [
      item.start_date,
      item.section.start_date,
      item.section.course.display_start_date || item.section.course.start_date,
    ].compact.max
  end
end
