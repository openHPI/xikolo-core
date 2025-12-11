# frozen_string_literal: true

module QuizService
class QuizSubmissionFreeTextAnswersController < QuizSubmissionAnswersController # rubocop:disable Layout/IndentationWidth
  private
  def klass
    QuizSubmissionFreeTextAnswer
  end
end
end
