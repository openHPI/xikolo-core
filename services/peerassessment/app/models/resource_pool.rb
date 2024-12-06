# frozen_string_literal: true

class ResourcePool < ApplicationRecord
  belongs_to :peer_assessment
  has_many :pool_entries

  validates :purpose, presence: true

  def initial_locks
    purpose == 'review' ? peer_assessment.grading_step.required_reviews : 1
  end
end
