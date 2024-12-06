# frozen_string_literal: true

class Comment::Store < ApplicationOperation
  attr_reader :comment

  def initialize(comment, params)
    super()

    @comment = comment
    @params = params
  end

  def call
    unless @params.key? :text
      comment.update @params
      return comment
    end
    text = @params.delete(:text)
    comment.assign_attributes @params
    configure_processor! text
    process_text_and_save
    comment
  end

  protected

  attr_reader :processor

  def configure_processor!(input)
    @processor = Xikolo::S3::TextWithUploadsProcessor.new \
      bucket: :pinboard,
      purpose: 'pinboard_commentable_text',
      current: comment.text,
      text: input
    processor.on_new do |upload|
      id = UUID4.new.to_str(format: :base62)
      original_filename = upload.sanitized_name
      {
        key: key_prefix + "/#{id}/#{original_filename}",
        acl: 'public-read',
        cache_control: 'public, max-age=7776000',
        content_disposition: "attachment; filename=\"#{original_filename}\"",
        content_type: upload.content_type,
      }
    end
  end

  def process_text_and_save
    processor.parse!
    comment.text = processor.result
    if processor.valid? && comment.save
      processor.commit!

      read_by_author!
      subscribe_author!

      true
    else
      processor.rollback!
      processor.errors.each do |_url, code, _message|
        comment.errors.add :text, code.to_s
      end
      false
    end
  end

  def key_prefix
    cid = UUID4(comment.commentable.question.course_id).to_str(format: :base62)
    qid = UUID4(comment.commentable.question.id).to_str(format: :base62)
    if comment.commentable.question.learning_room_id?
      lid = UUID4(comment.commentable.question.learning_room_id).to_str(format: :base62)
      "courses/#{cid}/collabspaces/#{lid}/topics/#{qid}"
    else
      "courses/#{cid}/topics/#{qid}"
    end
  end

  # rubocop:disable Rails/SkipsModelValidations
  def read_by_author!
    return if comment.commentable.is_a?(Question) &&
              comment.commentable.blocked?

    Watch.find_or_create_by!(
      user_id: comment.user_id,
      question_id:
    ).touch
  rescue ActiveRecord::RecordNotUnique
    retry
  end
  # rubocop:enable all

  def subscribe_author!
    return if comment.commentable.is_a?(Question) &&
              comment.commentable.blocked?

    Subscription.find_or_create_by! \
      user_id: comment.user_id,
      question_id:
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def question_id
    return comment.commentable_id if comment.commentable.is_a? Question

    comment.commentable.question_id
  end
end
