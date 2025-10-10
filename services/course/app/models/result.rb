# frozen_string_literal: true

class Result < ApplicationRecord
  self.table_name = :results

  validates :user_id, presence: true
  validates :dpoints,
    numericality: {only_integer: true, message: 'invalid_format'}
  belongs_to :item

  after_create do
    Msgr.publish(decorate.to_event, to: 'xikolo.course.result.create')
    update_enrollment_completion
  end
  after_update do
    Msgr.publish(decorate.to_event, to: 'xikolo.course.result.update')
    update_enrollment_completion
  end
  after_commit(on: :create) do
    NextDate::ItemSubmissionPublishingCreateWorker
      .perform_async(item_id, user_id)
    LearningEvaluation::UpdateSectionProgressWorker
      .perform_async(item.section_id, user_id)
  end
  after_commit(on: :update) do
    LearningEvaluation::UpdateSectionProgressWorker
      .perform_async(item.section_id, user_id)
  end

  # Group by user ID, selecting only the best result for an item per user
  def self.best_per_user(item_id)
    from(
      Result.where(item_id:)
        .select(
          '*,
          ROW_NUMBER() OVER(
            PARTITION BY user_id ORDER BY dpoints DESC
          ) row_num'
        ),
      :results
    ).where(row_num: 1)
  end

  private

  def update_enrollment_completion
    course = Course
      .joins(sections: :items)
      .where(sections: {items: {id: item_id}})
      .take!

    return unless course.records_released?

    EnrollmentCompletionWorker.perform_async(course.id, user_id)
  end
end
