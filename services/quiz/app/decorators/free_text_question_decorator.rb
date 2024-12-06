# frozen_string_literal: true

class FreeTextQuestionDecorator < QuestionDecorator
  def fields
    super.merge(
      case_sensitive:
    )
  end
end
