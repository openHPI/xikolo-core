# frozen_string_literal: true

module PinboardService
class Watch < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :watches

  # includes a question and the user who has seen this question
  belongs_to :question
  validates :user_id, presence: true
  validates :question_id, uniqueness: {scope: :user_id}

  delegate :course_id, to: :question
end
end
