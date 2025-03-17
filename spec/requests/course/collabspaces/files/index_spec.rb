# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Collabspace: Files: Index', type: :request do
  subject(:files) do
    get "/courses/#{course['course_code']}/learning_rooms/#{collabspace_id}/files", headers: {'HTTP_AUTHORIZATION' => "Xikolo-Session session_id=#{stub_session_id}"}
  end

  let(:course) { build(:'course:course', course_code: 'example') }
  let(:collabspace_id) { generate(:uuid) }
  let(:user_id) { generate(:user_id) }

  let(:collabspace_stub) do
    Stub.request(
      :collabspace, :get, "/collab_space/#{collabspace_id}"
    ).to_return Stub.json({
      id: collabspace_id,
      files_url: "/collab_spaces/#{collabspace_id}/files",
    })
  end
  let(:files_stub) do
    Stub.request(
      :collabspace, :get, "/collab_spaces/#{collabspace_id}/files",
      query: {page: 1, per_page: 10}
    ).to_return Stub.json([
      {id: '123',
       title: 'Data Science - Week 2',
       original_filename: 'DataScience_Week2_Notes.pdf',
       size: 2048,
       creator_id: user_id,
       created_at: 1.day.ago,
       blob_url: 'https://xikolo.de/files/123'},
      {id: '456',
       title: 'photo-whatsapp-123.png',
       original_filename: 'photo-whatsapp-123',
       size: 4096,
       creator_id: user_id,
       created_at: 1.week.ago,
       blob_url: 'https://xikolo.de/files/456'},
    ])
  end

  before do
    Stub.service(
      :account,
      sessions_url: '/sessions',
      session_url: '/sessions/{id}',
      user_url: '/user/{id}'
    )
    Stub.service(:course, build(:'course:root'))
    Stub.service(
      :collabspace,
      collab_space_url: '/collab_space/{id}',
      collab_space_files_url: '/collab_spaces/{collab_space_id}/files',
      memberships_url: '/memberships'
    )
  end

  context 'registered and enrolled user' do
    let(:enrollment_id) { generate(:uuid) }

    before do
      stub_user_request id: user_id, permissions: %w[course.content.access.available]

      Stub.request(:course, :get, '/courses/example').to_return Stub.json(course)

      # Because of the ensure_collabspace_membership before_action,
      # the membership is checked first.
      Stub.request(
        :collabspace, :get, '/memberships',
        query: {collab_space_id: collabspace_id, user_id:}
      ).to_return Stub.json([{
        collab_space_id: collabspace_id,
          user_id:,
          course_id: course['id'],
          status: 'admin',
      }])

      # The inside_course hook requests a bunch of other stuff:
      Stub.request(
        :course, :get, '/enrollments',
        query: {user_id:, course_id: course['id']}
      ).to_return Stub.json([{id: enrollment_id}])
      Stub.request(
        :course, :get, '/next_dates',
        query: hash_including(course_id: course['id'])
      ).to_return Stub.json([])

      # And finally, this is what we actually want:
      collabspace_stub

      # Finally...
      files_stub

      Stub.request(
        :account, :get, "/user/#{user_id}"
      ).to_return Stub.json({
        id: user_id,
        display_name: 'Jane Doe',
        avatar_url: 'https://xikolo.de/files/123',
      })
    end

    it 'renders the files overview' do
      files
      expect(response).to be_successful
      expect(response.body).to include('Data Science - Week 2', 'photo-whatsapp-123')
      expect(response.body).to include('Jane Doe')
      expect(response.body).to include('2 KB', '4 KB')
    end

    it 'loads the collabspace and respective files' do
      files
      expect(collabspace_stub).to have_been_requested.once
      expect(files_stub).to have_been_requested.once
    end

    context '(with pagination)' do
      subject(:files) do
        get "/courses/#{course['course_code']}/learning_rooms/#{collabspace_id}/files?page=2&per_page=1", headers: {'HTTP_AUTHORIZATION' => "Xikolo-Session session_id=#{stub_session_id}"}
      end

      before do
        Stub.request(
          :collabspace, :get, "/collab_spaces/#{collabspace_id}/files",
          query: {page: 2, per_page: 1}
        ).to_return Stub.json([
          {id: '123',
            title: 'Data Science - Week 2',
            original_filename: 'DataScience_Week2_Notes.pdf',
            size: 2048,
            creator_id: user_id,
            created_at: 1.day.ago,
            blob_url: 'https://xikolo.de/files/123'},
        ], headers: {'X-Total-Pages' => 3, 'X-Current-Page' => 2})
      end

      it 'renders the correct content and pagination links' do
        files
        expect(response).to be_successful
        expect(response.body).to include('Data Science - Week 2')
        expect(response.body).to match(/<a[^>]+rel="prev"[^>]+\?page=1[^>]+>/)
        expect(response.body).to match(/<a[^>]+rel="next"[^>]+\?page=3[^>]+>/)
      end
    end
  end
end
