# frozen_string_literal: true

require 'spec_helper'

shared_examples 'updates with stage visual' do
  let!(:store_stub) { stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>') }

  before do
    stub_request(:head, file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end

  it { is_expected.to respond_with :no_content }

  it 'instructs S3 to move the file to the correct bucket' do
    update_course
    expect(store_stub).to have_been_requested
  end

  it 'updates the stage visual url referencing the file in the new bucket' do
    expect { update_course }.to change { course.reload.stage_visual_url }
      .from(old_store_stub_url).to match store_stub_url
  end
end

shared_examples 'does not update the stage visual' do |error_details|
  it 'does not update the course with stage visual url' do
    expect { update_course }.to raise_error(Restify::ClientError)
    expect(course.reload.stage_visual_url).to match old_store_stub_url
  end

  it 'raises an unprocessable entity error' do
    expect { update_course }.to raise_error(Restify::UnprocessableEntity) do |error|
      expect(error.errors).to eq error_details
    end
  end
end

shared_examples 'does not delete the old stage visual' do
  it 'does not delete the old stage visual' do
    expect { update_course }.to raise_error(Restify::ClientError)
    expect(FileDeletionWorker.jobs).to be_empty
  end
end

shared_examples 'deletes the stage visual' do
  it { is_expected.to respond_with :no_content }

  it 'schedules the removal of the old stage visual' do
    update_course
    expect(FileDeletionWorker.jobs.last['args']).to eq [old_stage_visual_uri]
  end

  it 'updates the stage visual url to nil' do
    expect { update_course }.to change { course.reload.stage_visual_url }
      .from(old_store_stub_url).to be_nil
  end
end

RSpec.describe 'Courses: Update with stage visual', type: :request do
  subject(:update_course) { api.rel(:course).patch(data, params: {id: course.id}).value! }

  let!(:course) { create(:course, initial_params) }
  let(:api) { Restify.new(:test).get.value! }
  let(:upload_id) { '83aebd2a-f026-4d58-8a61-5ee4f1a7cbfa' }
  let(:file_name) { 'image.jpg' }
  let(:file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{file_name}" }
  let(:cluster) { create(:cluster) }
  let(:classifiers) { {cluster.id => ['Internet Technology 2', 'Beginner', 'Cat3', 'Cat4']} }

  before do
    Stub.service(:account, build(:'account:root'))

    Stub.request(:account, :get, '/grants').with(
      query: {
        context: course.context_id,
        role: 'course.visitor',
      }
    ).and_return Stub.json([])
  end

  context 'when uploads first stage visual' do
    let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-public/courses/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{file_name}} }
    let(:old_store_stub_url) { nil }
    let(:initial_params) { {classifiers: {cluster.id => %w[databases pro-track]}} }

    context 'with stage_visual_upload_id' do
      let(:data) do
        {
          title: 'new course title',
          classifiers:,
          proctored: true,
          invite_only: true,
          stage_visual_upload_id: upload_id,
        }
      end

      before do
        stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads%2F#{upload_id}")
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
        it_behaves_like 'updates with stage visual'
      end

      context 'when upload was rejected' do
        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
              'X-Amz-Meta-Xikolo-State' => 'rejected',
            }
          )
        end

        error_details = {'stage_visual_upload_id' => ['invalid upload']}
        it_behaves_like 'does not update the stage visual', error_details
      end

      context 'without access permission' do
        before do
          stub_request(:head, file_url).to_return(status: 403)
        end

        error_details = {'stage_visual_upload_id' => ['could not process file upload']}
        it_behaves_like 'does not update the stage visual', error_details
      end

      context 'when saving to destination is forbidden' do
        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
          stub_request(:put, store_stub_url).to_return(status: 403)
        end

        error_details = {'stage_visual_upload_id' => ['could not process file upload']}
        it_behaves_like 'does not update the stage visual', error_details
      end
    end

    context 'with stage_visual_uri' do
      let(:data) do
        {
          title: 'new course title',
          classifiers:,
          proctored: true,
          invite_only: true,
          stage_visual_upload_id: upload_id,
          stage_visual_uri: "upload://#{upload_id}/#{file_name}",
        }
      end

      before do
        stub_request(:head, store_stub_url).and_return(status: 404)
      end

      context 'when upload is successful' do
        it_behaves_like 'updates with stage visual'
      end

      context 'when upload was rejected' do
        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
              'X-Amz-Meta-Xikolo-State' => 'rejected',
            }
          )
        end

        error_details = {'stage_visual_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
        it_behaves_like 'does not update the stage visual', error_details
      end

      context 'without access permission' do
        before do
          stub_request(:head, file_url).to_return(status: 403)
        end

        error_details = {'stage_visual_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
        it_behaves_like 'does not update the stage visual', error_details
      end

      context 'when saving to destination is forbidden' do
        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
          stub_request(:put, store_stub_url).to_return(status: 403)
        end

        error_details = {'stage_visual_uri' => ['Could not save file - access to destination is forbidden.']}
        it_behaves_like 'does not update the stage visual', error_details
      end
    end
  end

  context 'when uploads another stage visual' do
    let(:old_stage_visual_uri) { "s3://xikolo-public/courses/1/42/#{file_name}" }
    let(:initial_params) { {classifiers: {cluster.id => %w[databases pro-track]}, stage_visual_uri: old_stage_visual_uri} }
    let(:new_file) { 'image2.jpg' }
    let(:file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{upload_id}/#{new_file}" }
    let(:store_stub_url) { %r{https://s3.xikolo.de/xikolo-public/courses/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{new_file}} }
    let(:old_store_stub_url) { %r{https://s3.xikolo.de/xikolo-public/courses/[0-9a-zA-Z]+/[0-9a-zA-Z]+/#{file_name}} }

    context 'with stage_visual_upload_id' do
      let(:data) { {stage_visual_upload_id: upload_id} }

      before do
        stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads%2F#{upload_id}")
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
              'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
        end

        it_behaves_like 'updates with stage visual'
        it 'schedules the removal of the old stage visual' do
          update_course
          expect(FileDeletionWorker.jobs.last['args']).to eq [old_stage_visual_uri]
        end
      end

      context 'when upload was rejected' do
        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
              'X-Amz-Meta-Xikolo-State' => 'rejected',
            }
          )
        end

        error_details = {'stage_visual_upload_id' => ['invalid upload']}
        it_behaves_like 'does not update the stage visual', error_details
        it_behaves_like 'does not delete the old stage visual'
      end

      context 'without access permission' do
        before do
          stub_request(:head, file_url).to_return(status: 403)
        end

        error_details = {'stage_visual_upload_id' => ['could not process file upload']}
        it_behaves_like 'does not update the stage visual', error_details
        it_behaves_like 'does not delete the old stage visual'
      end

      context 'when saving to destination is forbidden' do
        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
          stub_request(:put, store_stub_url).to_return(status: 403)
        end

        error_details = {'stage_visual_upload_id' => ['could not process file upload']}
        it_behaves_like 'does not update the stage visual', error_details
        it_behaves_like 'does not delete the old stage visual'
      end
    end

    context 'with stage_visual_uri' do
      let(:data) { {stage_visual_upload_id: upload_id, stage_visual_uri: "upload://#{upload_id}/#{new_file}"} }
      let(:store_stub) { stub_request(:put, store_stub_url).to_return(status: 200, body: '<xml></xml>') }

      before do
        store_stub
        stub_request(:head, file_url).to_return(
          status: 200,
          headers: {
            'Content-Type' => 'inode/x-empty',
            'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
            'X-Amz-Meta-Xikolo-State' => 'accepted',
          }
        )
        stub_request(:head, store_stub_url).and_return(status: 404)
      end

      context 'when upload is successful' do
        it_behaves_like 'updates with stage visual'
        it 'schedules the removal of the old stage visual' do
          update_course
          expect(FileDeletionWorker.jobs.last['args']).to eq [old_stage_visual_uri]
        end
      end

      context 'when upload was rejected' do
        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
              'X-Amz-Meta-Xikolo-State' => 'rejected',
            }
          )
        end

        error_details = {'stage_visual_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
        it_behaves_like 'does not update the stage visual', error_details
        it_behaves_like 'does not delete the old stage visual'
      end

      context 'without access permission' do
        before do
          stub_request(:head, file_url).to_return(status: 403)
        end

        error_details = {'stage_visual_uri' => ['Upload not valid - either file upload was rejected or access to it is forbidden.']}
        it_behaves_like 'does not update the stage visual', error_details
        it_behaves_like 'does not delete the old stage visual'
      end

      context 'when saving to destination is forbidden' do
        before do
          stub_request(:head, file_url).to_return(
            status: 200,
            headers: {
              'Content-Type' => 'inode/x-empty',
              'X-Amz-Meta-Xikolo-Purpose' => 'course_course_stage_visual',
              'X-Amz-Meta-Xikolo-State' => 'accepted',
            }
          )
          stub_request(:put, store_stub_url).to_return(status: 403)
        end

        error_details = {'stage_visual_uri' => ['Could not save file - access to destination is forbidden.']}
        it_behaves_like 'does not update the stage visual', error_details
        it_behaves_like 'does not delete the old stage visual'
      end

      context 'when the stage_visual_uri is nil' do
        let(:data) { {stage_visual_upload_id: upload_id, stage_visual_uri: nil} }

        it_behaves_like 'deletes the stage visual'
      end
    end
  end
end
