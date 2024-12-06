# frozen_string_literal: true

require 'spec_helper'

describe 'Rails / Active Model: Markup attributes' do
  let(:model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :text, Xikolo::S3::Markup.new(
        uploads: {purpose: 'foobar', content_type: 'image/*'}
      )
    end
  end

  it 'can be initialized with a string' do
    obj = model.new
    obj.text = 'hello world'

    expect(obj.text.to_s).to eq 'hello world'
  end

  it 'is nil by default' do
    obj = model.new

    expect(obj.text).to eq nil
  end

  it 'accepts an explicit nil' do
    obj = model.new(text: nil)

    expect(obj.text).to eq nil
  end

  describe 'compatibility with MarkdownInput in xi-web' do
    it 'stores options for upload capabilities' do
      upload_opts = model.attribute_types['text'].uploads

      expect(upload_opts[:purpose]).to eq 'foobar'
      expect(upload_opts[:content_type]).to eq 'image/*'
    end

    it 'can be converted to a hash' do
      obj = model.new(text: 'hello world')

      expect(obj.text.to_hash).to eq(
        'markup' => 'hello world',
        'url_mapping' => {},
        'other_files' => {}
      )
    end
  end

  context 'when a text includes internal S3 identifiers' do
    let(:text) do
      <<~MARKDOWN
        This is a plain link: s3://bucket/dir/dir/image.jpg
        ![image][image]
        [inline link](s3://bucket/dir/dir/document.pdf)
        [image]: s3://bucket/dir/dir/image.jpg
      MARKDOWN
    end

    it 'offers a method for extracting the unique S3 identifiers' do
      obj = model.new(text:)

      expect(obj.text.file_refs).to match_array %w[
        s3://bucket/dir/dir/image.jpg
        s3://bucket/dir/dir/document.pdf
      ]
    end

    it 'offers a method for getting the public URLs' do
      obj = model.new(text:)

      expect(obj.text.external).to eq <<~MARKDOWN
        This is a plain link: https://s3.xikolo.de/bucket/dir/dir/image.jpg
        ![image][image]
        [inline link](https://s3.xikolo.de/bucket/dir/dir/document.pdf)
        [image]: https://s3.xikolo.de/bucket/dir/dir/image.jpg
      MARKDOWN
    end

    it 'knows how to map internal identifiers to public URLs' do
      obj = model.new(text:)

      expect(obj.text.url_mapping).to eq({
        's3://bucket/dir/dir/image.jpg' => 'https://s3.xikolo.de/bucket/dir/dir/image.jpg',
        's3://bucket/dir/dir/document.pdf' => 'https://s3.xikolo.de/bucket/dir/dir/document.pdf',
      })
    end

    it 'stores a map of base names for existing references' do
      obj = model.new(text:)

      expect(obj.text.other_files).to eq({
        's3://bucket/dir/dir/image.jpg' => 'image.jpg',
        's3://bucket/dir/dir/document.pdf' => 'document.pdf',
      })
    end

    # Required for compatibility with MarkdownInput in xi-web
    it 'includes the markup and these maps when converting to a hash' do
      obj = model.new(text:)

      expect(obj.text.to_hash).to eq(
        'markup' => text,
        'url_mapping' => {
          's3://bucket/dir/dir/image.jpg' => 'https://s3.xikolo.de/bucket/dir/dir/image.jpg',
          's3://bucket/dir/dir/document.pdf' => 'https://s3.xikolo.de/bucket/dir/dir/document.pdf',
        },
        'other_files' => {
          's3://bucket/dir/dir/image.jpg' => 'image.jpg',
          's3://bucket/dir/dir/document.pdf' => 'document.pdf',
        }
      )
    end
  end
end
