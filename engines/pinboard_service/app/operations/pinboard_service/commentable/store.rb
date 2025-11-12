# frozen_string_literal: true

module PinboardService
module Commentable # rubocop:disable Layout/IndentationWidth
  class Store < ApplicationOperation
    attr_reader :commentable

    def initialize(commentable, params)
      super()

      @commentable = commentable
      # Keep track of the old text, so we can check on it later when purging obsolete URIs
      @original_text = commentable.text
      @params = params
      @errors = []
    end

    def call
      commentable.assign_attributes @params.except(:text, :attachment_upload_id)
      process_text
      process_attachment
      commit!
      commentable
    end

    protected

    attr_reader :processor

    def commit!
      if @errors.empty? && commentable.save
        processor&.commit!
        Xikolo::S3.object(@old_attachment).delete if @old_attachment
        purge_obsolete_files!
        read_by_author! # mark commentable, i.e. the question, as read
        subscribe_author!
      else
        processor&.rollback!
        @new_attachment&.delete
        commentable.valid?
        @errors.each do |field, error|
          commentable.errors.add field, error
        end
      end
    end

    def process_text
      # Don't process text if it is not changed, e.g. by blocking/unblocking questions.
      return if @params[:text] == commentable.text

      configure_processor! @params.delete(:text)
      processor.parse!
      commentable.text = processor.result
      unless processor.valid?
        processor.errors.each do |_url, code, _message|
          @errors << [:text, code.to_s]
        end
      end
    end

    def process_attachment
      return unless @params.key? :attachment_upload_id

      upload = Xikolo::S3::SingleFileUpload.new \
        @params.delete(:attachment_upload_id),
        purpose: :pinboard_commentable_attachment
      return if upload.empty?

      upload_object = upload.accepted_file!
      bucket = Xikolo::S3.bucket_for(:pinboard)

      params = file_params(upload_object)

      object = bucket.object(params.delete(:key))
      object.copy_from(
        upload_object,
        params.merge(metadata_directive: 'REPLACE')
      )
      @old_attachment = commentable.attachment_uri
      commentable.attachment_uri = object.storage_uri
      @new_attachment = object.storage_uri
    rescue Aws::S3::Errors::ServiceError => e
      ::Mnemosyne.attach_error(e)
      ::Sentry.capture_exception(e)
      @errors << [:attachment_upload_id, 'could not process file upload']
    rescue Xikolo::S3::SingleFileUpload::InvalidUpload
      @errors << [:attachment_upload_id, 'invalid upload']
    end

    def configure_processor!(input)
      @processor = Xikolo::S3::TextWithUploadsProcessor.new \
        bucket: :pinboard,
        purpose: 'pinboard_commentable_text',
        current: commentable.text,
        text: input
      processor.on_new {|upload| file_params(upload) }
    end

    def file_params(upload)
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

    def key_prefix
      cid = UUID4(commentable.question.course_id).to_str(format: :base62)
      qid = UUID4(commentable.question.id).to_str(format: :base62)
      "courses/#{cid}/topics/#{qid}"
    end

    # rubocop:disable Rails/SkipsModelValidations
    def read_by_author!
      return if commentable.is_a?(Question) && commentable.blocked?

      Watch.find_or_create_by!(
        user_id: commentable.user_id,
        question_id:
      ).touch
    rescue ActiveRecord::RecordNotUnique
      retry
    end
    # rubocop:enable all

    def subscribe_author!
      return if commentable.is_a?(Question) && commentable.blocked?

      Subscription.find_or_create_by! \
        user_id: commentable.user_id,
        question_id:
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    def question_id
      return commentable.id if commentable.is_a? Question

      commentable.question_id
    end

    def purge_obsolete_files!
      # Prevent purging files present in the text when only the text is changed
      return if file_unchanged?

      obsolete_uris = processor&.obsolete_uris

      obsolete_uris&.each do |uri|
        Xikolo::S3.object(uri).delete
      end
    rescue Aws::S3::Errors::ServiceError
      # Fail gracefully
    end

    private

    def file_unchanged?
      # Capture embedded URLs or URIs that point to the same file location
      original_uris = Xikolo::S3.extract_file_refs(@original_text)
      updated_uris = Xikolo::S3.extract_file_refs(commentable.text)

      return true if original_uris.difference(updated_uris).empty?

      # This additional check is needed if the image is saved with its url format
      # e.g. when multiple images are present in the text
      original_uris.all? do |uri|
        commentable.text.include? Xikolo::S3.object(uri).public_url
      end
    end
  end
end
end
