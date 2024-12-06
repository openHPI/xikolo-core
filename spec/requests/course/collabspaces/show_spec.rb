# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Collabspace: Show', type: :request do
  subject(:show_collabspace) { get "/courses/#{course['id']}/learning_rooms/#{collabspace['id']}", headers: }

  let(:course) { build(:'course:course') }
  let(:collabspace) { build(:'collabspace:collabspace', course_id: course['id']) }
  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { %w[course.content.access.available] }

  before do
    stub_user_request(permissions:)
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{course['id']}")
      .to_return(Stub.json(course))
    Stub.request(:course, :get, '/next_dates', query: hash_including({}))
      .to_return Stub.json([])
    Stub.service(:collabspace,
      memberships_url: '/memberships{?user_id,status,kind,course_id}',
      collab_space_url: '/collab_spaces/{id}')
    Stub.request(:collabspace, :get, "/collab_spaces/#{collabspace['id']}")
      .to_return(Stub.json(collabspace))
    Stub.request(
      :collabspace, :get, '/memberships',
      query: hash_including(collab_space_id: collabspace['id'])
    ).to_return Stub.json([])
  end

  context 'when the URL has not been altered' do
    it 'shows the collabspace' do
      show_collabspace
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('My Collab Space')
    end
  end

  context 'when the URL has been altered' do
    subject(:show_collabspace) { get "/courses/#{other_course['id']}/learning_rooms/#{collabspace['id']}", headers: }

    let(:other_course) { build(:'course:course', id: generate(:course_id)) }

    before do
      Stub.request(:course, :get, "/courses/#{other_course['id']}")
        .to_return(Stub.json(other_course))
    end

    it 'does not show the collabspace' do
      expect { show_collabspace }.to raise_error Status::NotFound
    end
  end
end
