# frozen_string_literal: true

module QuizService
class AnswerDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def fields
    {
      id:,
      question_id:,
      comment:,
      position:,
      correct: correct.nil? ? false : correct,
      text:,
      type: "Xikolo::Quiz::#{type&.delete_prefix('QuizService::')}",
    }
  end

  def as_json(opts = {})
    fields.as_json(opts)
  end

  def as_event
    {
      question_id:,
    }.as_json
  end

  private

  def text
    markup = object.text
    if type == 'FreeTextAnswer'
      markup
    elsif context[:raw]
      Xikolo::S3.media_refs(markup, public: true).merge(markup:)
    else
      Xikolo::S3.externalize_file_refs markup, public: true
    end
  end
end
end
