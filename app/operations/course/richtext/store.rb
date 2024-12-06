# frozen_string_literal: true

module Course
  class Richtext
    class Store < ApplicationOperation
      def initialize(richtext, params)
        super()

        @richtext = richtext
        @params = params
      end

      def call
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
          @processor&.rollback!
        end
        @richtext
      end

      private

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
        return if @processor.obsolete_uris.empty?

        @processor.obsolete_uris.each do |uri|
          S3FileDeletionJob.set(wait: 1.hour).perform_later(uri) unless ::Course::Richtext.referenced?(uri)
        end
      end
    end
  end
end
