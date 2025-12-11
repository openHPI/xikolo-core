# frozen_string_literal: true

module QuizService
class QuizSubmissionSelectableAnswersController < QuizSubmissionAnswersController # rubocop:disable Layout/IndentationWidth
  private
  def klass
    QuizSubmissionSelectableAnswer
  end
end
end
