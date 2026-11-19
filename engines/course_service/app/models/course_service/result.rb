# frozen_string_literal: true

module CourseService
class Result < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :results

  validates :dpoints,
    numericality: {only_integer: true, message: 'invalid_format'}
  belongs_to :item
  belongs_to :user, class_name: 'AccountService::User'

  after_create do
    ResultCreateJob.perform_later(decorate.to_event)
  end
  after_commit(on: :create) do
    NextDate::ItemSubmissionPublishingCreateJob
      .perform_later(item_id, user_id)
    LearningEvaluation::UpdateSectionProgressJob
      .perform_later(item.section_id, user_id)
  end
  after_commit(on: :update) do
    LearningEvaluation::UpdateSectionProgressJob
      .perform_later(item.section_id, user_id)
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

  def self.best_for(item_id, user_id)
    where(item_id:, user_id:).order(dpoints: :desc).first
  end
end
end
