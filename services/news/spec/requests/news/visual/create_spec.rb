# frozen_string_literal: true

require 'spec_helper'

shared_examples 'creates with visual' do
  let!(:store_stub) { stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>') }

  before do
    stub_request(:head, file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'news_visual',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end

  it { is_expected.to respond_with :created }

  it 'instructs S3 to move the file to the correct bucket' do
    create_announcement
    expect(store_stub).to have_been_requested
  end

  it 'updates the avatar url referencing the file in the new bucket' do
    create_announcement
    expect(News.first.visual_url).to match store_stub_url
  end
end

shared_examples 'does not create' do |error_details|
  it 'does not create the announcement with visual url' do
    expect { create_announcement }.to raise_error(Restify::ClientError)
    expect(News.first.visual_url).to be_nil
  end

  it 'raises an unprocessable entity error' do
    expect { create_announcement }.to raise_error(Restify::UnprocessableEntity) do |error|
      expect(error.errors)
        .to eq error_details
    end
  end
end

RSpec.describe 'News: Create with visual', type: :request do
  subject(:create_announcement) { service.rel(:news_index).post(params).value! }

  let(:service) { Restify.new(:test).get.value! }
  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:file_url) do
    'http://s3.xikolo.de/xikolo-uploads/' \
      'uploads/f13d30d3-6369-4816-9695-af5318c8ac15/visual.png'
  end
  let(:store_stub_url) { %r{http://s3.xikolo.de/xikolo-public/news/[0-9a-zA-Z]+/visual_v1.png} }

  before do
    stub_request(:get,
      'http://s3.xikolo.de/xikolo-uploads?list-type=2&' \
      'prefix=uploads%2Ff13d30d3-6369-4816-9695-af5318c8ac15').to_return(
        status: 200,
        headers: {'Content-Type' => 'Content-Type: application/xml'},
        body: <<~XML)
          <?xml version="1.0" encoding="UTF-8"?>
          <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <Name>xikolo-uploads</Name>
            <Prefix>uploads/f13d30d3-6369-4816-9695-af5318c8ac15</Prefix>
            <IsTruncated>false</IsTruncated>
            <Contents>
              <Key>uploads/f13d30d3-6369-4816-9695-af5318c8ac15/visual.png</Key>
              <LastModified>2018-08-02T13:27:56.768Z</LastModified>
              <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
            </Contents>
          </ListBucketResult>
        XML
  end

  context 'with visual_upload_id' do
    let(:params) do
      attributes_for(:news).merge(
        title: 'Some title',
        text: 'A beautiful announcement text',
        visual_upload_id: upload_id
      )
    end

    context 'when upload is successful' do
      include_examples 'creates with visual'
    end

    context 'when upload was rejected' do
      before do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'news_visual',
            'X-Amz-Meta-Xikolo-State' => 'rejected',
          }
        )
      end

      error_details = {'visual_upload_id' => ['invalid upload']}
      include_examples 'does not create', error_details
    end

    context 'without access permission' do
      before do
        stub_request(:head, file_url).to_return(status: 403)
      end

      error_details = {'visual_upload_id' => ['could not process file upload']}
      include_examples 'does not create', error_details
    end

    context 'when saving to destination is forbidden' do
      before do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'news_visual',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
        stub_request(:put, store_stub_url).to_return(status: 403)
      end

      error_details = {'visual_upload_id' => ['could not process file upload']}
      include_examples 'does not create', error_details
    end
  end

  context 'with visual_uri' do
    let(:params) do
      attributes_for(:news).merge(
        title: 'Some title',
        text: 'A beautiful announcement text',
        visual_uri: "upload://#{upload_id}/visual.png"
      )
    end

    before do
      stub_request(:head, store_stub_url).and_return(status: 404)
    end

    context 'when upload is successful' do
      include_examples 'creates with visual'
    end

    context 'when upload was rejected' do
      before do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'news_visual',
            'X-Amz-Meta-Xikolo-State' => 'rejected',
          }
        )
      end

      error_details = {'visual_uri' => ['Upload not valid - ' \
                                        'either file upload was rejected or access to it is forbidden.']}
      include_examples 'does not create', error_details
    end

    context 'without access permission' do
      before do
        stub_request(:head, file_url).to_return(status: 403)
      end

      error_details = {'visual_uri' => ['Upload not valid - ' \
                                        'either file upload was rejected or access to it is forbidden.']}
      include_examples 'does not create', error_details
    end

    context 'when saving to destination is forbidden' do
      before do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'news_visual',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
        stub_request(:put, store_stub_url).to_return(status: 403)
      end

      error_details = {'visual_uri' => ['Could not save file - ' \
                                        'access to destination is forbidden.']}
      include_examples 'does not create', error_details
    end
  end
end
