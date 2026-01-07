# frozen_string_literal: true

require 'spec_helper'

shared_examples 'updates with picture' do
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

  it { is_expected.to respond_with :no_content }

  it 'instructs S3 to move the file to the correct bucket' do
    update_teacher
    expect(store_stub).to have_been_requested
  end

  it 'updates the picture url referencing the file in the new bucket' do
    expect { update_teacher }.to change { teacher.reload.picture_url }
      .from(old_store_stub_url).to match store_stub_url
  end
end

shared_examples 'does not update the picture' do |error_details|
  it 'does not update the teacher with picture url' do
    expect { update_teacher }.to raise_error(Restify::ClientError)
    expect(teacher.reload.picture_url).to match old_store_stub_url
  end

  it 'raises an unprocessable entity error' do
    expect { update_teacher }.to raise_error(Restify::UnprocessableEntity) do |error|
      expect(error.errors).to eq error_details
    end
  end
end

shared_examples 'does not delete the old picture' do
  it 'does not delete the old picture' do
    expect { update_teacher }.to raise_error(Restify::ClientError)
    expect(FileDeletionWorker.jobs).to be_empty
  end
end

RSpec.describe 'Teachers: Update with picture', type: :request do
  subject(:update_teacher) { api.rel(:teacher).patch(data, params: {id: teacher.id}).value! }

  let(:api) { restify_with_headers(course_service.root_url).get.value }
  let(:teacher) { create(:'course_service/teacher', initial_params) }
  let(:upload_id) { 'f13d30d3-6369-4816-9695-af5318c8ac15' }
  let(:file_name) { 'tux.jpg' }
  let(:file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{file_name}" }
  let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-public/teachers/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{file_name}} }

  context 'when uploads first picture' do
    let(:old_store_stub_url) { nil }
    let(:initial_params) { {} }

    context 'with picture_upload_id' do
      let(:data) { {picture_upload_id: upload_id} }

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
        it_behaves_like 'updates with picture'
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
        it_behaves_like 'does not update the picture', error_details
      end

      context 'without access permission' do
        before do
          stub_request(:head, file_url).to_return(status: 403)
        end

        error_details = {'picture_upload_id' => ['could not process file upload']}
        it_behaves_like 'does not update the picture', error_details
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
        it_behaves_like 'does not update the picture', error_details
      end
    end

    context 'with picture_uri' do
      let(:data) { {picture_upload_id: upload_id, picture_uri: "upload://#{upload_id}/#{file_name}"} }

      before do
        stub_request(:head, store_stub_url).and_return(status: 404)
      end

      context 'when upload is successful' do
        it_behaves_like 'updates with picture'
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
        it_behaves_like 'does not update the picture', error_details
      end

      context 'without access permission' do
        before do
          stub_request(:head, file_url).to_return(status: 403)
        end

        error_details = {'picture_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
        it_behaves_like 'does not update the picture', error_details
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
        it_behaves_like 'does not update the picture', error_details
      end
    end
  end

  context 'when uploads another picture' do
    let(:old_picture_uri) { "s3://xikolo-public/teachers/1/42/#{file_name}" }
    let(:initial_params) { {picture_uri: old_picture_uri} }
    let(:new_file) { 'tux2.jpg' }
    let(:file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{new_file}" }
    let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-public/teachers/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{new_file}} }
    let(:old_store_stub_url) { %r{https://s3.xikolo.de/xikolo-public/teachers/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{file_name}} }

    context 'with picture_upload_id' do
      let(:data) { {picture_upload_id: upload_id} }

      before do
        stub_request(:get, 'https://s3.xikolo.de/xikolo-uploads?list-type=2&' \
                           "prefix=uploads%2F#{upload_id}").to_return(
                             status: 200,
                             headers: {'Content-Type' => 'Content-Type: application/xml'},
                             body: <<~XML)
                               <?xml version="1.0" encoding="UTF-8"?>
                               <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
                                 <Name>xikolo-uploads</Name>
                                 <Prefix>uploads/#{upload_id}</Prefix>
                                 <IsTruncated>false</IsTruncated>
                                 <Contents>
                                   <Key>uploads/#{upload_id}/#{new_file}</Key>
                                   <LastModified>2018-08-02T13:27:56.768Z</LastModified>
                                   <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
                                 </Contents>
                               </ListBucketResult>
                             XML
      end

      context 'when upload is successful' do
        let(:store_stub) { stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>') }

        before do
          store_stub
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_teacher_picture',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        end

        it_behaves_like 'updates with picture'
        it 'schedules the removal of the old picture' do
          update_teacher
          expect(CourseService::FileDeletionWorker.jobs.last['args']).to eq [old_picture_uri]
        end
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
        it_behaves_like 'does not update the picture', error_details
      end

      context 'without access permission' do
        before do
          stub_request(:head, file_url).to_return(status: 403)
        end

        error_details = {'picture_upload_id' => ['could not process file upload']}
        it_behaves_like 'does not update the picture', error_details
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
        it_behaves_like 'does not update the picture', error_details
      end
    end

    context 'with picture_uri' do
      let(:data) { {picture_upload_id: upload_id, picture_uri: "upload://#{upload_id}/#{new_file}"} }

      before do
        stub_request(:head, store_stub_url).and_return(status: 404)
      end

      context 'when upload is successful' do
        let(:store_stub) { stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>') }

        before do
          store_stub
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_teacher_picture',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        end

        it_behaves_like 'updates with picture'
        it 'schedules the removal of the old picture' do
          update_teacher
          expect(CourseService::FileDeletionWorker.jobs.last['args']).to eq [old_picture_uri]
        end
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
        it_behaves_like 'does not update the picture', error_details
      end

      context 'without access permission' do
        before do
          stub_request(:head, file_url).to_return(status: 403)
        end

        error_details = {'picture_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
        it_behaves_like 'does not update the picture', error_details
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
        it_behaves_like 'does not update the picture', error_details
      end
    end
  end
end
