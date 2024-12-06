# frozen_string_literal: true

class PoolEntry < ApplicationRecord
  belongs_to :resource_pool
  belongs_to :submission
  has_one :shared_submission, through: :submission

  validates :available_locks, presence: true
  validates_uniqueness_of :submission_id, scope: :resource_pool_id
  validates_numericality_of :available_locks, greater_than_or_equal_to: 0

  def team_entries
    submission.team_submissions.collect do |s|
      s.pool_entries.find_by resource_pool_id:
    end
  end
end
