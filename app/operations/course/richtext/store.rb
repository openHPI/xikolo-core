# frozen_string_literal: true

module Course
  module Richtext
    class Store < ApplicationOperation
      def initialize(richtext, params)
        super()

        @richtext = richtext
        @params = params
        @new_uris = []
        @replaced_uris = []
      end

      def call
        handle_reading_material!
        return @richtext if @richtext.errors.any?

        if @params[:text].blank?
          @richtext.errors.add :text, :blank
        else
          text = @params.delete(:text)
          @richtext.assign_attributes @params
          configure_processor! text
          process_text
        end
        if @richtext.errors.blank? && @richtext.save
          remove_replaced_files!
        else
          rollback!
        end
        @richtext
      rescue ActiveRecord::RecordInvalid
        rollback!
        @richtext
      end

      private

      attr_reader :new_uris, :replaced_uris

      def handle_reading_material!
        if @params.key?(:reading_material_url)
          removal_requested = @params.delete(:reading_material_url).blank?
          return handle_removal! if removal_requested
        end

        handle_upload!
      end

      def handle_removal!
        @params.delete(:reading_material_upload_id)
        return unless @richtext.reading_material_uri

        replaced_uris << @richtext.reading_material_uri
        @richtext.reading_material_uri = nil
      end

      def handle_upload!
        upload_id = @params.delete(:reading_material_upload_id)
        return if upload_id.blank?

        upload = Xikolo::S3::SingleFileUpload.new(upload_id, purpose: 'richtext_material')
        return if upload.empty?

        copy_upload!(upload.accepted_file!)
      rescue Aws::S3::Errors::ServiceError, Xikolo::S3::SingleFileUpload::InvalidUpload => e
        ::Sentry.capture_exception(e)
        upload_failed!
      end

      def copy_upload!(upload_object)
        replaced_uris << @richtext.reading_material_uri if @richtext.reading_material_uri

        cid = UUID4(@richtext.course_id).to_str(format: :base62)
        key = "courses/#{cid}/rtfiles/#{upload_object.unique_sanitized_name}"
        object = Xikolo::S3.bucket_for(:course).object(key)
        object.copy_from(
          upload_object,
          metadata_directive: 'REPLACE',
          acl: 'public-read',
          content_type: upload_object.content_type,
          cache_control: 'public, max-age=7776000',
          content_disposition: "attachment; filename=\"#{upload_object.sanitized_name}\""
        )
        @richtext.reading_material_uri = object.storage_uri
        new_uris << object.storage_uri
      end

      def upload_failed!
        @richtext.errors.add :reading_material_uri, :upload_error
      end

      def rollback!
        @processor&.rollback!
        new_uris.each {|uri| Xikolo::S3.object(uri).delete }
      end

      def configure_processor!(text)
        @processor = Xikolo::S3::TextWithUploadsProcessor.new \
          bucket: :course,
          purpose: 'course_richtext',
          current: @richtext.text,
          text:,
          valid_refs: @richtext.text&.file_refs || []
        @processor.on_new do |upload|
          cid = UUID4(@richtext.course_id).to_s(format: :base62)
          {
            key: "courses/#{cid}/rtfiles/#{upload.unique_sanitized_name}",
            acl: 'public-read',
            cache_control: 'public, max-age=7776000',
            content_disposition: 'inline',
            content_type: upload.content_type,
          }
        end
      end

      def process_text
        @processor.parse!

        if @processor.result.blank?
          @richtext.errors.add :text, :blank
          return
        end

        # We cache the text in case of an error so we can display the text in the form.
        @richtext.text = @processor.result

        if @processor.valid?
          @processor.commit!
        else
          @processor.errors.each do |_url, code, _message|
            @richtext.errors.add :text, code
          end
        end
      end

      def remove_replaced_files!
        return if @processor.obsolete_uris.empty? && replaced_uris.empty?

        (@processor.obsolete_uris + replaced_uris).each do |uri|
          S3FileDeletionJob.set(wait: 1.hour).perform_later(uri) unless ::CourseService::Richtext.referenced?(uri)
        end
      end
    end
  end
end
