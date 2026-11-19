# frozen_string_literal: true

module CourseService
class Visit < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :visits
  self.primary_key = %i[item_id user_id]

  belongs_to :item
  belongs_to :user, class_name: '::AccountService::User'

  class << self
    def latest
      order(updated_at: :desc).limit(1)
    end

    def latest_for(user:, items:)
      where(user_id: user, item: items).latest
    end
  end

  def last_visited
    updated_at
  end

  # We want to create a visit event on every visit,
  # in opposite to on entity that we update in the service
  after_touch do
    VisitCreateJob.perform_later(decorate.to_event)
  end
  after_create do
    VisitCreateJob.perform_later(decorate.to_event)
  end
  after_commit(on: :create) do
    LearningEvaluation::UpdateSectionProgressJob
      .perform_later(item.section_id, user_id)
  end
end
end
