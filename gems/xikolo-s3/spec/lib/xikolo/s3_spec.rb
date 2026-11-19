# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::S3 do
  context '#object' do
    it 'Aws::S3::Object instance' do
      uri = 's3://xikolo-public/courses/example/visual.png'
      object = described_class.object(uri)
      expect(object).to be_a Aws::S3::Object
    end
  end

  context '#resource' do
    it 'builds a resource with client configuration from ENV' do
      expect { described_class.resource }.to_not raise_error
      expect(described_class.resource).to be_a Aws::S3::Resource
      expect(described_class.resource.client.config.endpoint.to_s).to eq 'https://s3.xikolo.de'
      expect(described_class.resource.client.config.region).to eq 'default'
      expect(described_class.resource.client.config.credentials.access_key_id).to eq 'access_key'
      expect(described_class.resource.client.config.credentials.secret_access_key).to eq 'secret_access_key'
      expect(described_class.resource.client.config.force_path_style).to be true
    end

    it 'raises RuntimeError without essential ENV configuration' do
      %w[S3_ACCESS_ID S3_ACCESS_KEY AWS_REGION].each do |key|
        ENV[key] = nil
        expect { described_class.resource }.to raise_error(RuntimeError)
      end
    end
  end

  context '#bucket_for' do
    it 'raises RuntimeError without configuration' do
      # clear configuration
      Xikolo.config.s3 = nil
      expect { described_class.bucket_for(:uploads) }.to \
        raise_error(RuntimeError)
    end

    it 'raises RuntimeError without buckets configuration' do
      Xikolo.config.s3 = {}
      expect { described_class.bucket_for(:uploads) }.to \
        raise_error(RuntimeError)
    end

    it 'raises ArgumentError for unknown bucket name' do
      Xikolo.config.s3 = {'buckets' => {'other' => 'xikolo-other'}}
      expect { described_class.bucket_for(:uploads) }.to \
        raise_error(ArgumentError)
    end

    it 'does not raise error for configured bucket task' do
      expect(described_class.bucket_for(:uploads)).to be_a Aws::S3::Bucket
      expect(described_class.bucket_for(:uploads).name).to eq 'xikolo-uploads'
    end
  end

  context '#externalize_file_refs' do
    it 'returns nil unchanged' do
      expect(described_class.externalize_file_refs(nil)).to be_nil
    end

    it 'raises an ArgumentError without public and expires_in argument' do
      expect { described_class.externalize_file_refs('s3://bucket/key') }.to \
        raise_error(ArgumentError)
    end

    it 'replaces s3 stores URIs with public urls for public: true' do
      source_text = 's3://bucket/dir/dir/file_v1.ext'
      dest_text = 'https://s3.xikolo.de/bucket/dir/dir/file_v1.ext'

      expect(described_class.externalize_file_refs(source_text, public: true)).to \
        eq dest_text
    end

    it 'replaces s3 stores URIs with presigned urls for expires_in: int' do
      source_text = 's3://bucket/dir/dir/file_v1.ext'
      dest_link = 'https://s3.xikolo.de/bucket/dir/dir/file_v1.ext?X-Amz-Algorithm'

      expect(described_class.externalize_file_refs(source_text, expires_in: 9000)).to \
        include dest_link
    end

    it 'replaces s3 stores URIs with presigned urls for expires_in: int and public: true' do
      source_text = 's3://bucket/dir/dir/file_v1.ext'
      dest_link = 'https://s3.xikolo.de/bucket/dir/dir/file_v1.ext?X-Amz-Algorithm'

      expect(described_class.externalize_file_refs(source_text, expires_in: 9000, public: true)).to \
        include dest_link
    end
  end

  context '#extract_file_refs' do
    it 'returns empty lists for nil' do
      expect(described_class.extract_file_refs(nil)).to eq []
    end

    it 'returns all found s3 urls' do
      source_md = '
        This is a plain link: s3://bucket/dir/dir/image.jpg

        ![image][image]

        [inline link](s3://bucket/dir/dir/document.pdf)

        [image]: s3://bucket/dir/dir/image.jpg
      '

      expect(described_class.extract_file_refs(source_md)).to match_array %w[
        s3://bucket/dir/dir/image.jpg
        s3://bucket/dir/dir/document.pdf
      ]
    end
  end

  context '#media_refs' do
    let(:source_text) do
      '
        This is a plain link: s3://bucket/dir/dir/image.jpg

        ![image][image]

        [inline link](s3://bucket/dir/dir/document.pdf)

        [image]: s3://bucket/dir/dir/image.jpg
      '
    end

    it 'returns empty lists for nil' do
      result = described_class.media_refs(nil)

      expect(result.keys).to match_array %i[url_mapping other_files]
      expect(result[:other_files]).to eq({})
      expect(result[:url_mapping]).to eq({})
    end

    it 'raises an ArgumentError without public and expires_in argument' do
      expect { described_class.media_refs('s3://bucket/key') }.to \
        raise_error(ArgumentError)
    end

    it 'replaces s3 stores URIs with public urls for public: true' do
      result = described_class.media_refs(source_text, public: true)

      expect(result.keys).to match_array %i[url_mapping other_files]
      expect(result[:other_files]).to eq({
        's3://bucket/dir/dir/image.jpg' => 'image.jpg',
        's3://bucket/dir/dir/document.pdf' => 'document.pdf',
      })
      expect(result[:url_mapping]).to eq({
        's3://bucket/dir/dir/image.jpg' => 'https://s3.xikolo.de/bucket/dir/dir/image.jpg',
        's3://bucket/dir/dir/document.pdf' => 'https://s3.xikolo.de/bucket/dir/dir/document.pdf',
      })
    end

    it 'replaces s3 stores URIs with presigned urls for expires_in: int' do
      result = described_class.media_refs(source_text, expires_in: 9000)

      expect(result.keys).to match_array %i[url_mapping other_files]
      expect(result[:other_files]).to eq({
        's3://bucket/dir/dir/image.jpg' => 'image.jpg',
        's3://bucket/dir/dir/document.pdf' => 'document.pdf',
      })
      expect(result[:url_mapping].keys).to match_array %w[
        s3://bucket/dir/dir/image.jpg
        s3://bucket/dir/dir/document.pdf
      ]
      expect(result[:url_mapping]['s3://bucket/dir/dir/image.jpg']).to \
        start_with 'https://s3.xikolo.de/bucket/dir/dir/image.jpg?X-Amz-Algorithm'
      expect(result[:url_mapping]['s3://bucket/dir/dir/document.pdf']).to \
        start_with 'https://s3.xikolo.de/bucket/dir/dir/document.pdf?X-Amz-Algorithm'
    end

    it 'replaces s3 stores URIs with presigned urls for expires_in: int and public: true' do
      result = described_class.media_refs(source_text, expires_in: 9000, public: true)

      expect(result.keys).to match_array %i[url_mapping other_files]
      expect(result[:other_files]).to eq({
        's3://bucket/dir/dir/image.jpg' => 'image.jpg',
        's3://bucket/dir/dir/document.pdf' => 'document.pdf',
      })
      expect(result[:url_mapping].keys).to match_array %w[
        s3://bucket/dir/dir/image.jpg
        s3://bucket/dir/dir/document.pdf
      ]
      expect(result[:url_mapping]['s3://bucket/dir/dir/image.jpg']).to \
        start_with 'https://s3.xikolo.de/bucket/dir/dir/image.jpg?X-Amz-Algorithm'
      expect(result[:url_mapping]['s3://bucket/dir/dir/document.pdf']).to \
        start_with 'https://s3.xikolo.de/bucket/dir/dir/document.pdf?X-Amz-Algorithm'
    end
  end

  describe '#copy_to' do
    subject(:copy_to) { described_class.copy_to(source, target:, bucket:, acl:, content_disposition:) }
    let(:source) { described_class.object('s3://xikolo-public/courses/example/visual.png') }
    let(:target) { 'courses/example/visual.png' }
    let(:bucket) { :uploads }
    let(:acl) { 'public-read' }
    let(:content_disposition) { 'inline' }

    context 'without a source' do
      let(:source) { nil }

      it 'raises an ArgumentError' do
        expect { copy_to }.to raise_error(ArgumentError, 'Pass valid source and acl')
      end
    end

    context 'with a blank target' do
      let(:target) { '' }

      it 'raises an ArgumentError' do
        expect { copy_to }.to raise_error(ArgumentError, ':key must not be blank')
      end
    end

    context 'with an unknown bucket' do
      let(:bucket) { :public }

      it 'raises an ArgumentError' do
        expect do
          copy_to
        end.to raise_error(ArgumentError, 'Configure the public bucket in Xikolo.config.s3[\'buckets\']!')
      end
    end

    context 'with a blank ACL' do
      let(:acl) { '' }

      it 'raises an ArgumentError' do
        expect { copy_to }.to raise_error(ArgumentError, 'Pass valid source and acl')
      end
    end
  end
end
