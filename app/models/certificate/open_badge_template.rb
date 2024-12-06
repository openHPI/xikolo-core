# frozen_string_literal: true

module Certificate
  class OpenBadgeTemplate < ::ApplicationRecord
    validates :course_id, uniqueness: true
    validate :valid_s3_reference_or_upload

    after_commit :delete_s3_object!, on: :destroy

    belongs_to :course, class_name: 'Course::Course'
    has_many :open_badges,
      foreign_key: :template_id,
      dependent: :destroy,
      inverse_of: :open_badge_template

    ## ROUTE HELPERS
    ## Ensure that Rails routing helpers can be used directly with OpenBadgeTemplate instances.

    def self.model_name
      ActiveModel::Name.new(self, nil, 'OpenBadgeTemplate')
    end

    def to_param
      id
    end

    def bake!(user_id)
      begin
        record = RecordOfAchievement.find_or_create_by!(
          course_id:,
          user_id:
        )
      rescue ActiveRecord::RecordNotUnique
        retry
      end

      begin
        V2::OpenBadge
          .find_or_create_by!(record:, template_id: id)
          .tap(&:bake!)
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    rescue ActiveRecord::RecordInvalid
      raise CertificateNotGranted
    rescue ::Certificate::OpenBadge::InvalidAssertion
      # This is considered a known issue. Known issues are handled in the
      # `the_assertion` method, resulting in a blank assertion being returned.
    end

    def file_url
      # return a public URL here, because its used in the badge class representation
      Xikolo::S3.object(file_uri).public_url if file_uri?
    end

    def process_upload!(upload_id)
      @upload_error = false
      return unless valid?

      upload = Xikolo::S3::SingleFileUpload.new upload_id,
        purpose: 'certificate_openbadge_template'
      @upload_error = nil
      return if upload.empty?

      upload_object = upload.accepted_file!
      original_filename = File.basename upload_object.key
      extname = File.extname original_filename
      bucket = Xikolo::S3.bucket_for(:certificate)
      tid = UUID4(id).to_s(format: :base62)
      object = bucket.object("openbadge_templates/#{tid}#{extname}")
      object.copy_from(
        upload_object,
        metadata_directive: 'REPLACE',
        acl: 'public-read',
        content_type: upload_object.content_type,
        content_disposition: "attachment; filename=\"#{original_filename}\""
      )
      self.file_uri = object.storage_uri

      purge_badge_files! if open_badges.any?
    rescue Aws::S3::Errors::ServiceError => e
      ::Mnemosyne.attach_error(e)
      ::Sentry.capture_exception(e)
      @upload_error = 'could not process file upload'
    rescue RuntimeError
      @upload_error = 'invalid upload'
    end

    def valid_s3_reference_or_upload
      if @upload_error
        errors.add :file, @upload_error
      elsif @upload_error == false
        # We are in process_upload!, ignore for now.
      elsif !file_uri?
        errors.add :file, 'upload missing'
      end
    end

    private

    def delete_s3_object!
      S3FileDeletionJob.perform_now(file_uri)
    end

    def purge_badge_files!
      bucket = Xikolo::S3.bucket_for(:certificate)
      objects = open_badges.map do |badge|
        {key: badge.file_key}
      end

      bucket.delete_objects({
        delete: {objects:},
      })

      open_badges.update_all file_uri: nil # rubocop:disable Rails/SkipsModelValidations
    end

    class CertificateNotGranted < RuntimeError; end
  end
end
