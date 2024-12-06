# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Collabspace: Files: Destroy', type: :request do
  subject(:delete_file) do
    delete "/courses/#{course['course_code']}/learning_rooms/#{collabspace_id}/files/#{file_id}",
      headers: {'HTTP_AUTHORIZATION' => "Xikolo-Session session_id=#{stub_session_id}"}
  end

  let(:course) { build(:'course:course', course_code: 'example') }
  let(:collabspace_id) { SecureRandom.uuid }
  let(:file_id) { SecureRandom.uuid }
  let(:creator_id) { generate(:user_id) }
  let(:current_user_id) { generate(:user_id) }
  let(:permissions) { %w[course.content.access.available] }
  let(:collabspace_role) { 'regular' }
  let(:get_file_stub) do
    Stub.request(
      :collabspace, :get, "/files/#{file_id}"
    ).to_return Stub.json({
      title: 'DataScience_Week2_Notes.pdf',
      creator_id:,
      self_url: "/files/#{file_id}",
    })
  end
  let(:destroy_file_stub) do
    Stub.request(
      :collabspace, :delete, "/files/#{file_id}"
    ).to_return Stub.response(status: 200)
  end

  before do
    Stub.service(
      :account,
      sessions_url: '/sessions',
      session_url: '/sessions/{id}'
    )
    stub_user_request(id: current_user_id, permissions:)

    Stub.service(:course, course_url: '/courses/{id}')
    Stub.request(:course, :get, '/courses/example').to_return Stub.json(course)

    Stub.service(
      :collabspace,
      memberships_url: '/memberships',
      file_url: '/files/{id}'
    )
    Stub.request(
      :collabspace, :get, '/memberships',
      query: {collab_space_id: collabspace_id, user_id: current_user_id}
    ).to_return Stub.json([{
      collab_space_id: collabspace_id,
      user_id: current_user_id,
      course_id: course['id'],
      status: collabspace_role,
    }])
    get_file_stub
    destroy_file_stub
  end

  shared_examples 'deletable file' do
    it 'file can be deleted' do
      delete_file
      expect(get_file_stub).to have_been_requested
      expect(destroy_file_stub).to have_been_requested
    end
  end

  context 'as any regular collabspace member' do
    it 'can not delete the file' do
      delete_file
      expect(get_file_stub).to have_been_requested
      expect(destroy_file_stub).not_to have_been_requested
    end
  end

  context 'as collabspace mentor' do
    let(:collabspace_role) { 'mentor' }

    it_behaves_like 'deletable file'
  end

  context 'as collabspace admin' do
    let(:collabspace_role) { 'admin' }

    it_behaves_like 'deletable file'
  end

  context 'as file owner' do
    let(:current_user_id) { creator_id }

    it_behaves_like 'deletable file'
  end

  context 'as course or platform admin' do
    let(:current_user_id) { creator_id }
    let(:permissions) { %w[course.content.access.available collabspace.file.manage] }

    it_behaves_like 'deletable file'
  end
end
