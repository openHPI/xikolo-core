# frozen_string_literal: true

module Xikolo::S3
  class TextWithUploadsProcessor
    attr_reader :result, :errors

    def initialize(bucket:, purpose:, text:, current:, valid_refs: [], check_override: true) # rubocop:disable Metrics/ParameterLists
      @bucket = bucket
      @purpose = purpose
      @text = text
      @current_text = current
      @errors = []
      @uploaded = []
      @replaced = []
      @current_refs = if current
                        Xikolo::S3.extract_file_refs(current)
                      else
                        []
                      end
      @valid_refs = valid_refs
      @check_override = check_override
    end

    def on_new(&block)
      @new_callback = block
    end

    def parse!
      return unless @text # simply skip nil as value

      processed_uploads = {}
      @text.scan Xikolo::S3.url_regex do |match|
        validate_ref! match
      end
      @result = @text.gsub %r{upload://[-a-zA-Z0-9./_]*} do |match|
        if processed_uploads.key? match
          processed_uploads[match]
        else
          processed_uploads[match] = process_upload match
        end
      end
    end

    def commit!; end

    def obsolete_uris
      @current_refs
    end

    def rollback!
      @uploaded.each(&:delete)
    end

    def valid?
      @errors.empty?
    end

    private

    def validate_ref!(match)
      if @current_refs.include? match
        @current_refs.delete match
        @valid_refs << match
        return true
      end
      return true if @valid_refs.include? match

      @errors.append([match, :rtfile_unknown_ref,
                      'Adding unknown file refs is not supported'])
    end

    def process_upload(match)
      uri = URI.parse match
      upload = upload_bucket.object("uploads/#{uri.host}#{uri.path}")
      unless upload.metadata['xikolo-state'] == 'accepted' \
          && upload.metadata['xikolo-purpose'] == @purpose
        @errors.append([match, :rtfile_rejected, 'upload is not valid'])
        return match
      end
      params = @new_callback.yield upload
      destination = Xikolo::S3.bucket_for(@bucket).object(params.delete(:key))
      if @check_override && exists?(destination)
        @errors.append([match, :rtfile_exists, 'Destination already exists?'])
        return match
      end
      destination.copy_from(upload, params.merge(metadata_directive: 'REPLACE'))
      @uploaded << destination
      destination.storage_uri
    rescue Aws::S3::Errors::ConfigurationMissingError => e
      Sentry.capture_exception(e)
      @errors.append([match, :rtfile_unconfigured, e.message])
      match
    rescue Aws::S3::Errors::ServiceError => e
      Sentry.capture_exception(e)
      @errors.append([match, :rtfile_error, 'upload failed'])
      match
    end

    def exists?(obj)
      obj.exists?
    rescue Aws::S3::Errors::Forbidden
      false
    end

    def upload_bucket
      @upload_bucket ||= Xikolo::S3.bucket_for(:uploads)
    end
  end
end
