# frozen_string_literal: true

module PinboardService
class Vote < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :votes

  belongs_to :votable, polymorphic: true

  delegate :course_id, to: :votable, allow_nil: true

  validates :user_id, presence: true
  validates_uniqueness_of :user_id, scope: %i[votable_id votable_type]
  validates_inclusion_of :value, in: [-1, 0, 1]

  after_create { Msgr.publish(decorate.to_event, to: 'xikolo.pinboard.vote.create') }
end
end
