# frozen_string_literal: true

module PinboardService
class Vote < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :votes

  belongs_to :votable, polymorphic: true

  delegate :course_id, to: :votable, allow_nil: true

  validates :user_id, presence: true
  validates :user_id, uniqueness: {scope: %i[votable_id votable_type]}
  validates :value, inclusion: {in: [-1, 0, 1]}

  after_create { VoteCreateJob.perform_later(decorate.to_event) }
end
end
