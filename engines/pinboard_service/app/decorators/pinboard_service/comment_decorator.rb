# frozen_string_literal: true

module PinboardService
class CommentDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def basic
    {
      id:,
      text:,
      commentable_id:,
      commentable_type:,
      user_id:,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      abuse_report_state: workflow_state,
      abuse_report_count: abuse_reports.size,
    }
  end

  def as_json(opts = {})
    attrs = basic
    if context[:user_watch]
      attrs[:read] = commentable.user_watch && (updated_at < commentable.user_watch.updated_at)
    end
    attrs.as_json(opts)
  end

  def to_event
    basic.merge!(
      course_id:,
      technical: technical?,
      question_id:
    )
  end

  def commentable_type
    super.delete_prefix('PinboardService::')
  end

  def text
    if with_uris?
      # Edit: Display text only for edit
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
