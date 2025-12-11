# frozen_string_literal: true

module QuizService
class FreeTextQuestionDecorator < QuestionDecorator # rubocop:disable Layout/IndentationWidth
  def fields
    super.merge(
      case_sensitive:
    )
  end
end
end
