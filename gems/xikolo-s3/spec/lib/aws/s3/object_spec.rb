# frozen_string_literal: true

require 'spec_helper'

describe Aws::S3::Object do
  let(:config) do
    {
      'endpoint' => 'https://s3.xikolo.de',
      'region' => 'default',
      'access_key_id' => 'access_key',
      'secret_access_key' => 'secret_access_key',
    }.symbolize_keys
  end
  let(:resource) { Aws::S3::Resource.new client: Aws::S3::Client.new(config) }
  let(:object) { bucket.object(object_name) }
  let(:bucket_name) { 'xikolo-bucket' }
  let(:bucket) { resource.bucket(bucket_name) }
  let(:object_name) { 'courses/34/files/42.pdf' }

  context '#storage_uri' do
    it 'returns a s3 uri to be used with Xikolo::S3.object' do
      expect(object.storage_uri).to eq 's3://xikolo-bucket/courses/34/files/42.pdf'
    end
  end

  context '#extname' do
    it 'returns the extension based on the object key' do
      expect(object.extname).to eq '.pdf'
    end
  end

  context '#sanitized_name' do
    it 'returns the filename based on the object key' do
      expect(object.sanitized_name).to eq '42.pdf'
    end

    it 'replaced whitespaces with underscore' do
      obj = bucket.object('prefix/File with Whitespaces.pdf')
      expect(obj.sanitized_name).to eq 'File_with_Whitespaces.pdf'
    end

    it 'replaced none-url characters with underscores' do
      obj = bucket.object('prefix/file. .(4).+.:.&.pdf')
      expect(obj.sanitized_name).to eq 'file._._4_._._._.pdf'
    end
  end

  describe '#unique_sanitized_name' do
    it 'returns the sanitized filename prefixed with a unique identifier' do
      obj = bucket.object('prefix/with whitespace.pdf')
      expect(obj.unique_sanitized_name).to match(%r{^[[:alnum:]]{14,22}/with_whitespace.pdf$})
    end
  end
end
