# frozen_string_literal: true

module Course
  class Visual
    class Store < ApplicationOperation
      class OperationError < StandardError; end

      # @param visual [Course::Visual]
      # @param params [Hash] a hash of params (with symbol keys!)
      def initialize(visual, params)
        super()

        @visual = visual
        @params = params

        @upload_errors = {}
        @new_uris = []
      end

      Success = Struct.new(:message)
      Error = Struct.new(:message)

      def call
        begin
          ActiveRecord::Base.transaction do
            ##
            # 1. Process the visual image upload and handle possible errors.
            # If the provided value is `nil`, e.g. because the image is removed,
            # the upload actions will be skipped(see the implementation).
            if @params.key?(:image_uri)
              upload_via_uri('image', @params[:image_uri], 'course_course_image')
              # Please note: Deleting replaced or removed (S3) images will be
              # handled by the after commit hook on the visual resource.
              @visual.image_uri = nil if @params[:image_uri].nil?
            elsif @params.key?(:image_upload_id)
              upload_via_id('image', @params[:image_upload_id], 'course_course_image')
            end

            if @upload_errors.any?
              process_errors
              raise OperationError.new 'visual_update_error'
            end

            ##
            # 2. Update the course teaser video, which requires to update
            # the corresponding video resource or destroy it if needed.
            if @params[:video_stream_id].blank? && !subtitles_upload.empty?
              raise OperationError.new 'teaser_video_missing'
            end

            if @visual.video
              if @params[:video_stream_id].present?
                @visual.video.update!(
                  pip_stream_id: @params[:video_stream_id],
                  title: 'Teaser Video'
                )
                # Destroy the video subtitles if the teaser video has been changed.
                @visual.video.subtitles.destroy_all if @visual.video.pip_stream_id_previously_changed?
              else
                begin
                  # The course does not have a teaser video, destroy it. This will
                  # also destroy all attached subtitles via dependent destroy.
                  @visual.video.destroy!
                rescue ActiveRecord::DeleteRestrictionError
                  # Fail gracefully if the video is still associated with a
                  # course item. Explicitly remove the video from the visual
                  # to not rely on the order dependency of `dependent_destroy`
                  # options in the `Video::Video` model.
                  @visual.update!(video_id: nil)
                end
              end
            elsif @params[:video_stream_id].present?
              @visual.video = Video::Video.create!(
                pip_stream_id: @params[:video_stream_id],
                title: 'Teaser Video'
              )
            end

            @visual.save!
          end
        rescue OperationError => e
          return result Error.new e.message
        rescue ActiveRecord::RecordInvalid
          # TODO: This error handling is very generic. We can use the actual
          # errors to add mote helpful error messages, specifically they can
          # be added inline.
          return result Error.new 'visual_update_error'
        end

        # Attach the subtitles when the teaser video update was successful.
        if @visual.video_stream.present? && !subtitles_upload.empty?
          # TODO: This error handling is very generic. We can use the actual
          # errors to add more helpful error messages, specifically they can
          # be added inline to the form.
          video = Video::Store.call(@visual.video,
            {subtitles_upload_id: @params[:subtitles_upload_id]})
          if video.errors.any?
            return result Error.new 'subtitles_update_error'
          end
        end

        result Success.new
      end

      private

      def upload_via_id(upload_name, upload_value, purpose)
        upload = Xikolo::S3::SingleFileUpload.new(upload_value, purpose:)

        return if upload.empty?

        upload_object = upload.accepted_file!
        bucket = Xikolo::S3.bucket_for(:course)
        uid = UUID4(@visual.course_id).to_s(format: :base62)
        key = "courses/#{uid}/#{upload_object.unique_sanitized_name}"
        object = bucket.object(key)
        object.copy_from(
          upload_object,
          metadata_directive: 'REPLACE',
          acl: 'public-read',
          cache_control: 'public, max-age=7776000',
          content_type: upload_object.content_type,
          content_disposition: 'inline'
        )

        @visual.image_uri = object.storage_uri
        @new_uris << object.storage_uri
      rescue Aws::S3::Errors::ServiceError => e
        Sentry.capture_exception(e)
        @upload_errors[:"#{upload_name}_upload_id"] = 'could not process file upload'
      rescue RuntimeError
        @upload_errors[:"#{upload_name}_upload_id"] = 'invalid upload'
      end

      def upload_via_uri(upload_name, upload_value, purpose)
        return if upload_value.nil?

        upload = Xikolo::S3::UploadByUri.new(uri: upload_value, purpose:)
        unless upload.valid?
          @upload_errors[:"#{upload_name}_uri"] = 'Upload not valid - ' \
                                                  'either file upload was rejected or access to it is forbidden.'
          return
        end

        uid = UUID4(@visual.course_id).to_s(format: :base62)
        result = upload.save \
          bucket: :course,
          key: "courses/#{uid}/#{upload.upload.unique_sanitized_name}",
          acl: 'public-read',
          cache_control: 'public, max-age=7776000',
          content_type: upload.content_type,
          content_disposition: 'inline'

        if result.is_a?(Symbol)
          @upload_errors[:"#{upload_name}_uri"] = 'Could not save file - ' \
                                                  'access to destination is forbidden.'
          return
        end

        @visual.image_uri = result.storage_uri
        @new_uris << result.storage_uri
      end

      def process_errors
        # Delete files that already have been uploaded to S3.
        @new_uris.each {|uri| S3FileDeletionJob.perform_later(uri) }
        # Add errors to resource.
        @upload_errors.each {|key, error| @visual.errors.add key, error }
      end

      def subtitles_upload
        @subtitles_upload ||= Xikolo::S3::SingleFileUpload.new(
          @params[:subtitles_upload_id],
          purpose: 'course_visual_subtitles'
        )
      end
    end
  end
end
