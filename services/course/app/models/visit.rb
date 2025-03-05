# frozen_string_literal: true

class Visit < ApplicationRecord
  self.primary_key = %i[item_id user_id]

  validates :user_id, presence: true
  validates :item_id, uniqueness: {scope: :user_id}
  belongs_to :item

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
    Msgr.publish(decorate.to_event, to: 'xikolo.course.visit.create')
  end
  after_create do
    Msgr.publish(decorate.to_event, to: 'xikolo.course.visit.create')

    course = Course
      .joins(sections: :items)
      .where(sections: {items: {id: item_id}})
      .take!

    if course.records_released?
      EnrollmentCompletionWorker.perform_async(course.id, user_id)
    end
  end
  after_commit(on: :create) do
    LearningEvaluation::UpdateSectionProgressWorker
      .perform_async(item.section_id, user_id)
  end
end
