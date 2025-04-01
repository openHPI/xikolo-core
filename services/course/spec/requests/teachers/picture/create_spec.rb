# frozen_string_literal: true

require 'spec_helper'

shared_examples 'creates with picture' do
  let!(:store_stub) { stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>') }

  before do
    stub_request(:head, file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'course_teacher_picture',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end

  it { is_expected.to respond_with :created }

  it 'creates a new teacher' do
    expect { create_teacher }.to change(Teacher, :count).from(0).to(1)
  end

  it 'responds with a follow location to created resource' do
    expect(create_teacher.follow.to_s).to eq teacher_url(Teacher.last, host: 'course.xikolo.tld')
  end

  it 'instructs S3 to move the file to the correct bucket' do
    create_teacher
    expect(store_stub).to have_been_requested
  end

  it 'set the picture url referencing the file in the new bucket' do
    create_teacher
    expect(Teacher.first.picture_url).to match store_stub_url
  end
end

shared_examples 'does not create' do |error_details|
  it 'does not create the teacher with picture url' do
    expect { create_teacher }.to raise_error(Restify::ClientError)
    expect(Teacher.first).to be_nil
  end

  it 'raises an unprocessable entity error' do
    expect { create_teacher }.to raise_error(Restify::UnprocessableEntity) do |error|
      expect(error.errors).to eq error_details
    end
  end
end

describe 'Teachers: Create with picture', type: :request do
  subject(:create_teacher) { api.rel(:teachers).post(data).value! }

  let(:api) { Restify.new(:test).get.value }
  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:file_name) { 'tux.jpg' }
  let(:file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{file_name}" }
  let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-public/teachers/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{file_name}} }

  context 'with picture_upload_id' do
    let(:data) do
      {
        id: generate(:user_id),
        name: 'This is a text',
        description: {de: 'Deutsch!'}.stringify_keys,
        picture_upload_id: upload_id,
      }
    end

    before do
      stub_request(:get, 'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
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
                <Key>uploads/#{upload_id}/#{file_name}</Key>
                <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
              </Contents>
            </ListBucketResult>
          XML
    end

    context 'when upload is successful' do
      include_examples 'creates with picture'
    end

    context 'when upload was rejected' do
      before do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'course_teacher_picture',
            'X-Amz-Meta-Xikolo-State' => 'rejected',
          }
        )
      end

      error_details = {'picture_upload_id' => ['invalid upload']}
      include_examples 'does not create', error_details
    end

    context 'without access permission' do
      before do
        stub_request(:head, file_url).to_return(status: 403)
      end

      error_details = {'picture_upload_id' => ['could not process file upload']}
      include_examples 'does not create', error_details
    end

    context 'when saving to destination is forbidden' do
      before do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'course_teacher_picture',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
        stub_request(:put, store_stub_url).to_return(status: 403)
      end

      error_details = {'picture_upload_id' => ['could not process file upload']}
      include_examples 'does not create', error_details
    end
  end

  context 'with picture_uri' do
    let(:data) do
      {
        id: generate(:user_id),
        name: 'This is a text',
        description: {de: 'Deutsch!'}.stringify_keys,
        picture_uri: "upload://#{upload_id}/#{file_name}",
      }
    end

    before do
      stub_request(:head, store_stub_url).and_return(status: 404)
    end

    context 'when upload is successful' do
      include_examples 'creates with picture'
    end

    context 'when upload was rejected' do
      before do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'course_teacher_picture',
            'X-Amz-Meta-Xikolo-State' => 'rejected',
          }
        )
      end

      error_details = {'picture_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
      include_examples 'does not create', error_details
    end

    context 'without access permission' do
      before do
        stub_request(:head, file_url).to_return(status: 403)
      end

      error_details = {'picture_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
      include_examples 'does not create', error_details
    end

    context 'when saving to destination is forbidden' do
      before do
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'course_teacher_picture',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
        stub_request(:put, store_stub_url).to_return(status: 403)
      end

      error_details = {'picture_uri' => ['Could not save file - access to destination is forbidden.']}
      include_examples 'does not create', error_details
    end
  end
end
