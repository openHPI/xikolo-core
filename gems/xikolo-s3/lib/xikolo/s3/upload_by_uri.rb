# frozen_string_literal: true

module Xikolo::S3
  class UploadByUri
    attr_reader :upload

    def initialize(uri:, purpose:, check_override: true)
      @uri = uri
      @purpose = purpose
      @check_override = check_override
    end

    def valid?
      upload!
      upload.metadata['xikolo-state'] == 'accepted' \
        && upload.metadata['xikolo-purpose'] == @purpose.to_s
    rescue Aws::S3::Errors::ServiceError => e
      Sentry.capture_exception(e)
      false
    end

    def save(params)
      upload!
      dest_obj = Xikolo::S3.bucket_for(params.delete(:bucket)).object(params.delete(:key))
      return :rtfile_exists if exists?(dest_obj)

      dest_obj.copy_from(upload, params.merge(metadata_directive: 'REPLACE'))
      dest_obj
    rescue Aws::S3::Errors::ConfigurationMissingError => e
      Sentry.capture_exception(e)
      :rtfile_unconfigured
    rescue Aws::S3::Errors::ServiceError => e
      Sentry.capture_exception(e)
      :rtfile_error
    end

    def key
      upload!.key
    end

    def content_type
      upload!.content_type
    end

    def extname
      ::File.extname key
    end

    def sanitized_name
      basename.gsub(/[^-a-zA-Z0-9_.]+/, '_')
    end

    private

    def exists?(obj)
      return false unless @check_override

      obj.exists?
    rescue Aws::S3::Errors::Forbidden
      false
    end

    def upload!
      return @upload if @upload

      upload_bucket ||= Xikolo::S3.bucket_for(:uploads)
      uri = URI.parse @uri
      @upload = upload_bucket.object("uploads/#{uri.host}#{uri.path}")
    end

    def basename
      ::File.basename key
    end
  end
end
