# frozen_string_literal: true

module PinboardService
class AnswerDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def basic
    {
      id:,
      text:,
      question_id:,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      user_id:,
      votes: votes_sum,
      attachment_url:,
      abuse_report_state: workflow_state,
      abuse_report_count: abuse_reports.size,
      unhelpful_answer_score:,
      ranking:,
    }
  end

  def as_json(opts = {})
    attrs = basic

    if context[:vote_value]
      attrs[:vote_value_for_requested_user] = requested_user_vote.try(:value) || 0
    end

    if context[:user_watch]
      attrs[:read] = question.user_watch && (updated_at < question.user_watch.updated_at)
    end

    attrs.as_json(opts)
  end

  def to_event
    basic.merge!(
      course_id:,
      technical: technical?
    )
  end

  def text
    if with_uris?
      # Edit: Render text and images and display text in the input field (with URIs)
      object.text
    elsif with_input_data?
      Xikolo::S3.media_refs(object.text, public: true)
        .merge('markup' => object.text)
    else
      # Show: Render text & images for show
      Xikolo::S3.externalize_file_refs(object.text, public: true)
    end
  end

  def with_input_data?
    context[:text_purpose] == 'input'
  end

  def with_uris?
    context[:text_purpose] == 'display'
  end
end
end
