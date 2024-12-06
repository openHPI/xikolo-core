# frozen_string_literal: true

# Keep `item_submission_publishing` next date in sync with
# the actual item
#
# This worker update attributes of created
# `item_submission_publishing` next date. They are created
# once a result is created. They persist item attributes.
# This worker updates all these persisted attributes.
class NextDate::ItemSubmissionPublishingSyncWorker
  include Sidekiq::Job

  def perform(item_id)
    @item_id = item_id

    dates = NextDate
      .where(slot_id:)
      .user_specific

    if applicable?
      dates.update_all(attrs) # rubocop:disable Rails/SkipsModelValidations
    else
      dates.delete_all
    end
  end

  private

  def item
    @item ||= Item.where(published: true).find_by(id: @item_id)
  end

  def applicable?
    # The `item_submission_publishing` next dates must be
    # kept if only a `submission_deadline` is present to
    # hide `item_submission_deadline` next dates.
    # With a `submission_publishing_date` for the item,
    # the `item_submission_publishing` next dates need to be updated,
    # no matter if there is a `submission_deadline`.
    # With neither a `submission_deadline` nor a `submission_publishing_date`,
    # the `item_submission_publishing` next dates must not be kept to
    # hide `item_submission_deadline` next dates nor the
    # `item_submission_publishing` next dates need to be updated.
    item && (item.submission_publishing_date? || item.submission_deadline?)
  end

  def attrs
    {
      type: 'item_submission_publishing',
      resource_type: 'item',
      resource_id: @item_id,
      course_id: item.section.course.id,
      date: item.submission_publishing_date || 1.second.ago,
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
