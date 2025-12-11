# frozen_string_literal: true

module QuizService
class QuestionStatisticsDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      id: question_id,
      type: question_type.delete_prefix('QuizService::'),
      text: question_text,
      position: question_position,
      max_points:,
      avg_points:,
      submission_count:,
      submission_user_count:,
      answers: answer_statistics,
      incorrect_submission_count:,
      correct_submission_count:,
      partly_correct_submission_count:,
    }.as_json(opts)
  end
end
end
