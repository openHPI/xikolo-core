# frozen_string_literal: true

module PinboardService
class Watch < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :watches

  # includes a question and the user who has seen this question
  belongs_to :question
  validates :user_id, presence: true
  validates_uniqueness_of :question_id, scope: :user_id

  delegate :course_id, to: :question

  after_commit(on: :create) { notify :create }
  after_commit(on: :destroy) { notify :destroy }

  def notify(action_sym)
    Msgr.publish(decorate.to_event, to: "xikolo.pinboard.watch.#{action_sym.to_s.downcase}")
  end
end
end
