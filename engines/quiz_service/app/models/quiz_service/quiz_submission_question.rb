# frozen_string_literal: true

module QuizService
class QuizSubmissionQuestion < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :quiz_submission_questions

  belongs_to :quiz_submission
  has_many :quiz_submission_answers, dependent: :destroy

  validates :quiz_question_id, uniqueness: {scope: :quiz_submission_id}

  default_scope -> { order(:created_at) }

  def points
    if (original_points = read_attribute(:points))
      original_points
    else
      question = Question.find quiz_question_id
      user_answers = QuizSubmissionAnswer.where quiz_submission_question_id: id

      question.update_points_from_answer_object(self, user_answers)

      points
    end
  end
end
end
