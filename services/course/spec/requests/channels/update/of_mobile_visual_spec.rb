# frozen_string_literal: true

require 'spec_helper'

describe 'Channel: update of mobile visual', type: :request do
  subject(:action) do
    api.rel(:channel).patch({mobile_visual_upload_id: upload_id}, params: {id: channel.id}).value!
  end

  let(:api) { Restify.new(course_service.root_url).get.value }
  let(:channel) do
    create(:'course_service/channel',
      mobile_visual_uri: 's3://xikolo-public/channels/1/mobile_visual_v1.jpg')
  end

  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:file_url) do
    'https://s3.xikolo.de/xikolo-uploads/' \
      "uploads/#{upload_id}/tux.jpg"
  end

  context 'with valid upload' do
    let!(:store_stub) do
      stub_request(:put, %r{https://s3.xikolo.de/xikolo-public/
        channels/[0-9a-zA-Z]+/mobile_visual_v2.jpg}x).to_return(status: 200, body: '<xml></xml>')
    end

    before do
      stub_request(:get,
        'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
        "prefix=uploads%2F#{upload_id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
              <Contents>
                <Key>uploads/#{upload_id}/tux.jpg</Key>
                <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
              </Contents>
            </ListBucketResult>
          XML

      stub_request(:head, file_url).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'course_channel_mobile_visual',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
    end

    it { is_expected.to respond_with :no_content }

    it 'stores the mobile visual' do
      expect { action }.to change { channel.reload.mobile_visual_uri }
      expect(store_stub).to have_been_requested
    end

    it 'schedules removal of the old file' do
      action

      expect(CourseService::FileDeletionWorker.jobs.last['args']).to eq [
        's3://xikolo-public/channels/1/mobile_visual_v1.jpg',
      ]
    end
  end

  context 'with invalid file upload' do
    before do
      stub_request(:get,
        'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
        "prefix=uploads%2F#{upload_id}")
        .to_return(
          status: 200,
          headers: {'Content-Type' => 'Content-Type: application/xml'},
          body: <<~XML)
            <?xml version="1.0" encoding="UTF-8"?>
            <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
              <Name>xikolo-uploads</Name>
              <Prefix>uploads/#{upload_id}</Prefix>
              <IsTruncated>false</IsTruncated>
              <Contents>
                <Key>uploads/#{upload_id}/tux.jpg</Key>
                <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
              </Contents>
            </ListBucketResult>
          XML
    end

    it 'returns an error on inprocessible upload' do
      stub_request(:head, file_url).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'course_channel_mobile_visual',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )
      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'mobile_visual_upload_id' => ['invalid upload']
      end
    end

    it 'handles S3 errors during upload validating' do
      stub_request(:head, file_url).to_return(status: 403)

      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq \
          'mobile_visual_upload_id' => ['could not process file upload']
      end
    end

    it 'handles S3 errors during upload copying' do
      stub_request(:head, file_url).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'inode/x-empty',
          'X-Amz-Meta-Xikolo-Purpose' => 'course_channel_mobile_visual',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )

      stub_request(:put, %r{https://s3.xikolo.de/xikolo-public/
        channels/[0-9a-zA-Z]+/mobile_visual_v2.jpg}x).to_return(status: 403)

      expect { action }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq \
          'mobile_visual_upload_id' => ['could not process file upload']
      end
    end
  end
end
