# frozen_string_literal: true

module Course
  class Metadata
    class Store < ApplicationOperation
      def initialize(metadata, params)
        super()

        @metadata = metadata
        @params = params
        @metadata_types = [
          Metadata::TYPE::SKILLS,
          Metadata::TYPE::EDUCATIONAL_ALIGNMENT,
          Metadata::TYPE::LICENSE,
        ]
      end

      Success = Struct.new(:metadata)
      Error = Struct.new(:metadata)

      def call
        @metadata_types.each do |metadata_type|
          process_upload(metadata_type, @params.fetch(:"#{metadata_type}_upload_id", nil))
        end

        if @metadata.errors.any?
          return result Error.new(@metadata)
        end

        result Success.new(@metadata)
      end

      def process_upload(metadata_type, upload_id)
        return if upload_id.nil?

        upload = Xikolo::S3::SingleFileUpload.new(
          upload_id,
          purpose: 'course_metadata'
        )

        return if upload.empty?

        upload_object = upload.accepted_file!

        ActiveRecord::Base.transaction do
          Metadata.find_by(course_id: @metadata.course_id, name: metadata_type)&.destroy
          Metadata.create!(
            course_id: @metadata.course_id,
            name: metadata_type,
            version: Metadata::VERSION,
            data: JSON.parse(upload_object.get.body.read)
          )
        end
      rescue JSON::Schema::ValidationError, JSON::ParserError => e
        @metadata.errors.add(metadata_type, e.message)
      rescue ActiveRecord::RecordInvalid => e
        e.record.errors.each {|err| @metadata.errors.add(:base, "#{err.attribute} #{err.message}") }
      rescue Aws::S3::Errors::ServiceError => e
        ::Mnemosyne.attach_error(e)
        ::Sentry.capture_exception(e)
        @metadata.errors.add(:base, :upload_error)
      rescue RuntimeError
        @metadata.errors.add(:base, :upload_error)
      end
    end
  end
end
