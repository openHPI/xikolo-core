# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'aws-sdk-s3'
require 'uuid4'
require 'xikolo/config'

module Xikolo
  module S3
    class << self
      def bucket_for(name)
        configured_name = bucket_config[name.to_s]
        if configured_name.blank?
          raise ArgumentError.new \
            "Configure the #{name} bucket in Xikolo.config.s3['buckets']!"
        end
        resource.bucket configured_name
      end

      def object(uri)
        parsed = URI.parse uri
        unless parsed.scheme == 's3'
          raise "unknown storage schema in uri: #{uri}"
        end

        resource.bucket(parsed.host).object(parsed.path[1..].to_s)
      end

      def resource
        @resource ||= Aws::S3::Resource.new(client: Aws::S3::Client.new(client_config))
      end

      def stub_responses!(stubs)
        @resource = Aws::S3::Resource.new \
          client: Aws::S3::Client.new(stub_responses: stubs)
      end

      def extract_file_refs(text)
        return [] unless text

        text.to_s.scan(url_regex).uniq
      end

      def media_refs(text, public: false, expires_in: nil)
        return {url_mapping: {}, other_files: {}} unless text
        unless public || expires_in
          raise ArgumentError.new 'Pass public: true or expires_in argument'
        end

        url_mapping = {}
        other_files = {}
        extract_file_refs(text).each do |match|
          url_mapping[match] = if expires_in
                                 Xikolo::S3.object(match).presigned_url(:get, expires_in:)
                               elsif public
                                 Xikolo::S3.object(match).public_url
                               end
          other_files[match] = File.basename match
        end
        {url_mapping:, other_files:}
      end

      def externalize_file_refs(text, public: false, expires_in: nil)
        return nil unless text
        unless public || expires_in
          raise ArgumentError.new 'Pass public: true or expires_in argument'
        end

        text.gsub(url_regex) do |match|
          if expires_in
            Xikolo::S3.object(match).presigned_url(:get, expires_in:)
          elsif public
            Xikolo::S3.object(match).public_url
          end
        end
      end

      def copy_to(source_object, target:, bucket:, acl:, content_disposition: 'inline')
        if source_object.blank? || acl.blank?
          raise ArgumentError.new 'Pass valid source and acl'
        end

        copy = bucket_for(bucket).object(target)
        copy.copy_from(source_object, metadata_directive: 'REPLACE', acl:, content_disposition:)
        copy.storage_uri
      end

      def url_regex
        %r{s3://[-a-zA-Z0-9./_]*}
      end

      private

      def config
        @config ||= Xikolo.config.s3.tap do |cfg|
          next if cfg

          raise 'Configure S3 buckets and credentials via Xikolo.config.s3!'
        end
      end

      def client_config
        cfg = config['client'] || config['connect_info']
        if cfg
          cfg = cfg.symbolize_keys
          required_keys = %i[endpoint region access_key_id secret_access_key]
          cfg[:logger] = ::Rails.logger if defined?(::Rails)
          return cfg if (cfg.keys & required_keys).size == required_keys.size
        end
        raise 'Configure S3 credentials via Xikolo.config.s3["client"]!'
      end

      def bucket_config
        cfg = config['buckets']
        return cfg if cfg

        raise 'Configure S3 buckets via Xikolo.config.s3["buckets"]!'
      end
    end

    require 'xikolo/s3/upload_by_uri'
    require 'xikolo/s3/single_file_upload'
    require 'xikolo/s3/text_with_uploads_processor'

    begin
      require 'active_model'
    rescue LoadError
      # Optional dependency...
    else
      require 'xikolo/s3/markup'
    end
  end
end

class Aws::S3::Object
  def storage_uri
    "s3://#{bucket_name}/#{key}"
  end

  def extname
    ::File.extname key
  end

  ##
  # Generate a safe identifier based on the upload filename.
  #
  # Unless explicitly intended, +unique_sanitized_name+ should be preferred.
  def sanitized_name
    basename.gsub(/[^-a-zA-Z0-9_.]+/, '_')
  end

  ##
  # Generate a safe, unique identifier based on the upload filename.
  #
  # This method can be used to dynamically generate identifiers in
  # filenames, to prevent dirty browser caches when a new file with
  # the same filename is reuploaded to replace an old one.
  def unique_sanitized_name
    "#{::UUID4.new.to_str(format: :base62)}/#{sanitized_name}"
  end

  private

  def basename
    ::File.basename key
  end
end
