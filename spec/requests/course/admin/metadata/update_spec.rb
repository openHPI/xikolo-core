# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Admin: Metadata: Update', type: :request do
  subject(:update_metadata) do
    patch "/courses/#{course.id}/metadata", params:, headers:
  end

  let(:headers) { {} }
  let(:course) { create(:course) }
  let(:skills_upload_id) { generate(:uuid) }
  let(:alignment_upload_id) { generate(:uuid) }
  let(:license_upload_id) { generate(:uuid) }
  let(:skills_file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{skills_upload_id}/#{skills_file_name}" }
  let(:alignment_file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{alignment_upload_id}/#{alignment_file_name}" }
  let(:license_file_url) { "https://s3.xikolo.de/xikolo-uploads/uploads/#{license_upload_id}/#{license_file_name}" }
  let(:skills_file_name) { 'skills.json' }
  let(:alignment_file_name) { 'alignment.json' }
  let(:license_file_name) { 'license.json' }
  let(:skills_list_stub) do
    stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads%2F#{skills_upload_id}")
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'Content-Type: application/xml'},
        body: <<~XML)
          <?xml version="1.0" encoding="UTF-8"?>
          <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <Name>xikolo-uploads</Name>
            <Prefix>uploads/#{skills_upload_id}</Prefix>
            <IsTruncated>false</IsTruncated>
            <Contents>
              <Key>uploads/#{skills_upload_id}/#{skills_file_name}</Key>
              <LastModified>2018-08-02T13:27:56.768Z</LastModified>
              <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
            </Contents>
          </ListBucketResult>
        XML
  end
  let(:alignment_list_stub) do
    stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads%2F#{alignment_upload_id}")
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'Content-Type: application/xml'},
        body: <<~XML)
          <?xml version="1.0" encoding="UTF-8"?>
          <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <Name>xikolo-uploads</Name>
            <Prefix>uploads/#{alignment_upload_id}</Prefix>
            <IsTruncated>false</IsTruncated>
            <Contents>
              <Key>uploads/#{alignment_upload_id}/#{alignment_file_name}</Key>
              <LastModified>2018-08-02T13:27:56.768Z</LastModified>
              <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
            </Contents>
          </ListBucketResult>
        XML
  end
  let(:license_list_stub) do
    stub_request(:get, "https://s3.xikolo.de/xikolo-uploads?list-type=2&prefix=uploads%2F#{license_upload_id}")
      .to_return(
        status: 200,
        headers: {'Content-Type' => 'Content-Type: application/xml'},
        body: <<~XML)
          <?xml version="1.0" encoding="UTF-8"?>
          <ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
            <Name>xikolo-uploads</Name>
            <Prefix>uploads/#{license_upload_id}</Prefix>
            <IsTruncated>false</IsTruncated>
            <Contents>
              <Key>uploads/#{license_upload_id}/#{license_file_name}</Key>
              <LastModified>2018-08-02T13:27:56.768Z</LastModified>
              <ETag>&#34;d41d8cd98f00b204e9800998ecf8427e&#34;</ETag>
            </Contents>
          </ListBucketResult>
        XML
  end
  let(:skills_read_stub) do
    stub_request(:head, skills_file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'course_metadata',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end
  let(:alignment_read_stub) do
    stub_request(:head, alignment_file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'course_metadata',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end
  let(:license_read_stub) do
    stub_request(:head, license_file_url).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'inode/x-empty',
        'X-Amz-Meta-Xikolo-Purpose' => 'course_metadata',
        'X-Amz-Meta-Xikolo-State' => 'accepted',
      }
    )
  end
  let(:skills_store_stub) do
    stub_request(:get, skills_file_url).to_return(
      body: File.new('spec/support/files/course/metadata/skills_valid.json'),
      status: 200
    )
  end
  let(:alignment_store_stub) do
    stub_request(:get, alignment_file_url).to_return(
      body: File.new('spec/support/files/course/metadata/educational_alignment_valid.json'),
      status: 200
    )
  end
  let(:license_store_stub) do
    stub_request(:get, license_file_url).to_return(
      body: File.new('spec/support/files/course/metadata/license_valid.json'),
      status: 200
    )
  end

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course.id}")
      .to_return Stub.json(
        build(:'course:course', id: course.id, course_code: course.course_code)
      )
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])
    skills_list_stub
    alignment_list_stub
    license_list_stub
    skills_read_stub
    alignment_read_stub
    license_read_stub
  end

  context 'for logged-in users' do
    let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permission' do
      let(:permissions) { %w[course.course.edit course.content.access] }

      context 'with skills metadata' do
        let(:params) { {course_metadata: {skills_upload_id:}} }

        context 'with uploaded valid JSON file' do
          before { skills_store_stub }

          it 'successfully creates the metadata from the file' do
            expect { update_metadata }.to change(Course::Metadata, :count).from(0).to(1)
            expect(response).to redirect_to "/courses/#{course.course_code}/metadata/edit"
            expect(flash[:success].first).to eq 'The course metadata has been updated.'
          end
        end

        context 'with uploaded invalid JSON file' do
          before { skills_store_stub }

          let(:skills_store_stub) do
            stub_request(:get, skills_file_url).to_return(
              body: File.new('spec/support/files/course/metadata/skills_invalid.json'),
              status: 200
            )
          end

          it 'does not pass validation and shows an error message' do
            expect { update_metadata }.not_to change(Course::Metadata, :count).from(0)
            expect(response).to render_template :edit
            expect(flash[:error].first).to eq 'The course metadata could not be updated. Please verify your uploaded file and try again.'
            expect(response.body).to include 'did not contain a required property of'
          end
        end

        context 'with existing skills metadata' do
          before { skills_store_stub }

          let!(:metadata) { create(:metadata, :skills, course:) }

          it 'replaces the metadata' do
            expect { update_metadata }.to change { course.reload.skills.id }.from(metadata.id)
            expect(response).to redirect_to "/courses/#{course.course_code}/metadata/edit"
            expect(flash[:success].first).to eq 'The course metadata has been updated.'
          end
        end
      end

      context 'with educational alignment metadata' do
        let(:params) { {course_metadata: {educational_alignment_upload_id: alignment_upload_id}} }

        context 'with uploaded valid JSON file' do
          before { alignment_store_stub }

          it 'successfully creates the metadata from the file' do
            expect { update_metadata }.to change(Course::Metadata, :count).from(0).to(1)
            expect(response).to redirect_to "/courses/#{course.course_code}/metadata/edit"
            expect(flash[:success].first).to eq 'The course metadata has been updated.'
          end
        end

        context 'with uploaded invalid JSON file' do
          before { alignment_store_invalid_stub }

          let(:alignment_store_invalid_stub) do
            stub_request(:get, alignment_file_url).to_return(
              body: File.new('spec/support/files/course/metadata/educational_alignment_invalid.json'),
              status: 200
            )
          end

          it 'does not pass validation and shows an error message' do
            expect { update_metadata }.not_to change(Course::Metadata, :count).from(0)
            expect(response).to render_template :edit
            expect(flash[:error].first).to eq 'The course metadata could not be updated. Please verify your uploaded file and try again.'
            expect(response.body).to include 'did not contain a required property of'
          end
        end

        context 'with existing educational alignment metadata' do
          before { alignment_store_stub }

          let!(:metadata) { create(:metadata, :educational_alignment, course:) }

          it 'replaces the metadata' do
            expect { update_metadata }.to change { course.reload.educational_alignment.id }.from(metadata.id)
            expect(response).to redirect_to "/courses/#{course.course_code}/metadata/edit"
            expect(flash[:success].first).to eq 'The course metadata has been updated.'
          end
        end
      end

      context 'with license metadata' do
        let(:params) { {course_metadata: {license_upload_id:}} }

        context 'with uploaded valid JSON file' do
          before { license_store_stub }

          it 'successfully creates the metadata from the file' do
            expect { update_metadata }.to change(Course::Metadata, :count).from(0).to(1)
            expect(response).to redirect_to "/courses/#{course.course_code}/metadata/edit"
            expect(flash[:success].first).to eq 'The course metadata has been updated.'
          end
        end

        context 'with uploaded invalid JSON file' do
          before { license_store_invalid_stub }

          let(:license_store_invalid_stub) do
            stub_request(:get, license_file_url).to_return(
              body: File.new('spec/support/files/course/metadata/license_invalid.json'),
              status: 200
            )
          end

          it 'does not pass validation and shows an error message' do
            expect { update_metadata }.not_to change(Course::Metadata, :count).from(0)
            expect(response).to render_template :edit
            expect(flash[:error].first).to eq 'The course metadata could not be updated. Please verify your uploaded file and try again.'
            expect(response.body).to include 'of type null did not match the following type'
          end
        end

        context 'with existing license metadata' do
          before { license_store_stub }

          let!(:metadata) { create(:metadata, :license, course:) }

          it 'replaces the metadata' do
            expect { update_metadata }.to change { course.reload.license.id }.from(metadata.id)
            expect(response).to redirect_to "/courses/#{course.course_code}/metadata/edit"
            expect(flash[:success].first).to eq 'The course metadata has been updated.'
          end
        end
      end

      context 'with skills and educational alignment metadata' do
        let(:params) { {course_metadata: {skills_upload_id:, educational_alignment_upload_id: alignment_upload_id}} }

        before do
          skills_store_stub
          alignment_store_stub
        end

        it 'successfully creates the metadata from the file' do
          expect { update_metadata }.to change(Course::Metadata, :count).from(0).to(2)
          expect(response).to redirect_to "/courses/#{course.course_code}/metadata/edit"
          expect(flash[:success].first).to eq 'The course metadata has been updated.'
        end

        context 'with existing metadata' do
          let!(:skills) { create(:metadata, :skills, course:) }
          let!(:alignment) { create(:metadata, :educational_alignment, course:) }

          it 'deletes existing metadata' do
            update_metadata
            expect { skills.reload }.to raise_error(ActiveRecord::RecordNotFound)
            expect { alignment.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end
    end
  end

  context 'for anonymous users' do
    let(:params) { {course_metadata: {skills_upload_id:}} }

    it 'does not allow to create course metadata' do
      expect { update_metadata }.not_to change(Course::Metadata, :count).from(0)
      expect(response).to redirect_to "/courses/#{course.course_code}"
      expect(flash[:error].first).to eq 'Please log in to proceed.'
    end
  end
end
