# frozen_string_literal: true

class QuestionDecorator < Draper::Decorator
  delegate_all

  def basic
    {
      id:,
      title:,
      text:,
      video_timestamp:,
      video_id:,
      user_id:,
      accepted_answer_id:,
      course_id:,
      learning_room_id:,
      discussion_flag:,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      votes: votes_sum,
      views: watches.size,
      attachment_url:,
      sticky:,
      deleted:,
      closed:,
      implicit_tags: implicit_tags.to_a.map do |tag|
                       {name: tag.name,
                        referenced_resource: tag.referenced_resource,
                        id: tag.id}
                     end,
      user_tags: explicit_tags.to_a.map {|tag| {name: tag.name, id: tag.id} },
      abuse_report_state: workflow_state,
      abuse_report_count: abuse_reports.size,
    }
  end

  def as_json(opts = {})
    attrs = basic

    if context[:collection]
      attrs.merge!(
        answer_count: public_answers_count,
        comment_count: public_comments_count,
        answer_comment_count: public_answer_comments_count
      )
    end

    if context[:vote_value]
      attrs[:vote_value_for_requested_user] = requested_user_vote.try(:value) || 0
    end

    if context[:user_watch]
      attrs[:read] = user_watch && (updated_at < user_watch.updated_at)
    end
    attrs.as_json(opts)
  end

  def to_event
    attrs = basic
    attrs[:technical] = technical?
    if accepted_answer.present?
      attrs[:accepted_answer_user_id] = accepted_answer.user_id
    end
    attrs
  end

  def text
    if with_uris?
      object.text
    elsif with_input_data?
      Xikolo::S3.media_refs(object.text, public: true)
        .merge('markup' => object.text)
    else
      # For rendering text and images, image's URLs are returned
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
