# frozen_string_literal: true

module QuizService
class QuestionDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(opts = {})
    {
      **fields,
      **urls,
    }.as_json(opts)
  end

  def as_event
    {
      quiz_id:,
    }.as_json
  end

  private

  def fields
    {
      id:,
      quiz_id:,
      text: decorate_markup(text),
      points:,
      explanation: decorate_markup(explanation),
      shuffle_answers:,
      type: "Xikolo::Quiz::#{type.delete_prefix('QuizService::')}",
      position:,
      exclude_from_recap:,
      eligible_for_recap: recap?,
    }.tap do |attrs|
      if context[:selftests]
        attrs.merge!(
          answers: AnswerDecorator.decorate_collection(
            answers, context:
          )
        )
      end
    end
  end

  def urls
    {
      submission_statistic_url: h.submission_question_statistic_path(id:),
    }
  end

  def decorate_markup(markup)
    if context[:raw]
      Xikolo::S3.media_refs(markup, public: true).merge(markup:)
    else
      Xikolo::S3.externalize_file_refs markup, public: true
    end
  end
end
end
