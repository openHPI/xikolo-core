# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Collabspace: Files: Create', type: :request do
  subject(:create_file) do
    post "/courses/#{course['course_code']}/learning_rooms/#{collab_space_id}/files",
      headers: {'HTTP_AUTHORIZATION' => "Xikolo-Session session_id=#{stub_session_id}"},
      params:
  end

  let(:course) { build(:'course:course', course_code: 'example') }
  let(:collab_space_id) { SecureRandom.uuid }
  let(:user_id) { generate(:user_id) }
  let(:params) { {} }

  before do
    Stub.service(
      :account,
      sessions_url: '/sessions',
      session_url: '/sessions/{id}'
    )
    Stub.service(:course, build(:'course:root'))
    Stub.service(
      :collabspace,
      collab_space_url: '/collab_space/{id}',
      collab_space_files_url: '/collab_spaces/{collab_space_id}/files',
      memberships_url: '/memberships'
    )
    Stub.service(:peerassessment, build(:'peerassessment:root'))
  end

  context 'registered and enrolled user' do
    let(:enrollment_id) { SecureRandom.uuid }

    before do
      stub_user_request id: user_id, permissions: %w[course.content.access.available]

      Stub.request(:course, :get, '/courses/example').to_return Stub.json(course)

      # Because of the ensure_collabspace_membership before_action,
      # the membership is checked first.
      Stub.request(
        :collabspace, :get, '/memberships',
        query: {collab_space_id:, user_id:}
      ).to_return Stub.json([{
        collab_space_id:,
        user_id:,
        course_id: course['id'],
        status: 'admin',
      }])

      # The inside_course hook requests a bunch of stuff:
      Stub.request(
        :course, :get, '/enrollments',
        query: {user_id:, course_id: course['id']}
      ).to_return Stub.json([{id: enrollment_id}])
      Stub.request(
        :course, :get, '/next_dates',
        query: hash_including(course_id: course['id'])
      ).to_return Stub.json([])

      # And finally, the collab space is requested:
      Stub.request(
        :collabspace, :get, "/collab_space/#{collab_space_id}"
      ).to_return Stub.json({
        id: collab_space_id,
        files_url: "/collab_spaces/#{collab_space_id}/files",
      })

      # For some reason, peer assessments are requested
      Stub.request(
        :peerassessment, :get, '/peer_assessments',
        query: hash_including(course_id: course['id'])
      ).to_return Stub.json([])
    end

    context 'with invalid/missing collabspace file params' do
      let(:params) do
        {
          collabspace_file: {
            file_upload_name: 'DataScience_Week2_Notes.pdf',
          },
        }
      end

      it 'redirects to the files overview' do
        create_file
        expect(response).to redirect_to \
          course_learning_room_files_path(course['course_code'], collab_space_id)
      end
    end

    context 'with valid params' do
      let(:upload_id) { UUID4.new }
      let(:params) do
        {
          collabspace_file: {
            file_upload_id: upload_id,
            file_upload_name: 'DataScience_Week2_Notes.pdf',
          },
        }
      end
      let(:create_file_response) { Stub.response(status: 200) }
      let!(:create_file_stub) do
        Stub.request(
          :collabspace, :post, "/collab_spaces/#{collab_space_id}/files",
          body: {
            title: 'DataScience_Week2_Notes.pdf',
            creator_id: user_id,
            upload_uri: "upload://#{upload_id}/DataScience_Week2_Notes.pdf",
          }
        ).to_return create_file_response
      end

      it 'redirects to the files overview' do
        create_file
        expect(response).to redirect_to \
          course_learning_room_files_path(course['course_code'], collab_space_id)
      end

      it 'sends the meta data to the collabspace service to upload the file' do
        create_file
        expect(create_file_stub).to have_been_requested.once
      end

      context 'with error while uploading the file to the collabspace bucket' do
        let(:create_file_response) { Stub.response(status: 422) }

        it 'handles the error in some tbd way'
      end
    end
  end
end
