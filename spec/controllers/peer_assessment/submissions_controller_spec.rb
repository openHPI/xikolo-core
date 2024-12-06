# frozen_string_literal: true

require 'spec_helper'

describe PeerAssessment::SubmissionsController, type: :controller do
  let(:json) { response.parsed_body }

  let(:assessment_id) { SecureRandom.uuid }
  let(:step_id) { SecureRandom.uuid }
  let(:submission_id) { SecureRandom.uuid }
  let(:course_id) { SecureRandom.uuid }
  let(:user_id) { SecureRandom.uuid }
  let(:file_owner) { user_id }
  let(:item_id) { SecureRandom.uuid }
  let(:file_id) { SecureRandom.uuid }
  let(:attachments) { [] }
  let(:allowed_attachments) { 1 }
  let(:request_context_id) { course_context_id }
  let(:permissions) { ['course.content.access.available'] }

  before do
    Stub.service(
      :course,
      course_url: '/courses/{id}',
      enrollments_url: '/enrollments',
      item_url: '/items/{id}'
    )

    Stub.service(
      :peerassessment,
      submission_url: '/submissions/{id}',
      submissions_url: '/submissions',
      peer_assessment_url: '/peer_assessment/{id}'
    )

    Stub.request(
      :peerassessment, :get, "/peer_assessment/#{assessment_id}"
    ).to_return Stub.json({
      id: assessment_id,
      course_id:,
      attachments: [],
      allowed_attachments:,
    })

    Stub.request(
      :peerassessment, :get, "/peer_assessments/#{assessment_id}"
    ).to_return Stub.json({
      id: assessment_id,
      course_id:,
      attachments: [],
      allowed_attachments:,
    })

    Stub.request(
      :peerassessment, :get, '/participants',
      query: {user_id:, peer_assessment_id: assessment_id}
    ).to_return Stub.json([
      {current_step: step_id},
    ])

    Stub.request(
      :peerassessment, :get, '/steps',
      query: {peer_assessment_id: assessment_id}
    ).to_return Stub.json([
      {id: step_id, position: 1, open: true, deadline: 2.days.from_now.iso8601},
    ])

    Stub.request(
      :peerassessment, :get, "/submissions/#{submission_id}"
    ).to_return Stub.json([
      {id: submission_id, attachments:, user_id:},
    ])

    Stub.request(
      :peerassessment, :get, '/submissions',
      query: {peer_assessment_id: assessment_id, user_id:}
    ).to_return Stub.json([
      {id: submission_id, attachments:, user_id:, file_url: "/submissions/#{submission_id}/files/{id}"},
    ])

    Stub.request(
      :course, :get, "/courses/#{course_id}"
    ).to_return Stub.json({
      id: course_id,
      context_id: course_context_id,
      status: 'active',
    })

    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:}
    ).to_return Stub.json([
      {user_id:, course_id:},
    ])

    Stub.request(
      :course, :get, '/enrollments',
      query: {user_id:, course_id:}
    ).to_return Stub.json([
      {user_id:, course_id:},
    ])

    Stub.request(
      :course, :get, "/items/#{item_id}"
    ).to_return Stub.json({
      id: item_id,
    })

    stub_user id: user_id, permissions:
  end

  describe '#upload' do
    subject(:action) { post :upload, params: }

    before do
      Stub.request(
        :account, :get, "/users/#{user_id}"
      ).to_return Stub.json({
        id: user_id,
      })
    end

    let(:params) { {peer_assessment_id: assessment_id, step_id:} }

    context 'with submission having attachments' do
      let(:attachments) { [file_id] }

      it 'rejects new attachments' do
        expect(action).to have_http_status :bad_request
      end
    end
  end

  describe 'remove_file' do
    subject(:action) { delete :remove_file, params: }

    let(:params) { {peer_assessment_id: assessment_id, step_id:, file_id:} }
    let(:attachments) { [{id: file_id, user_id: file_owner}] }

    let!(:file_delete_stub) do
      Stub.request(
        :peerassessment, :delete, "/submissions/#{submission_id}/files/#{file_id}"
      ).to_return Stub.response(status: 204)
    end

    before do
      Stub.request(
        :account, :get, "/users/#{user_id}"
      ).to_return Stub.json({
        id: user_id,
      })
    end

    it 'can be removed' do
      action
      expect(file_delete_stub).to have_been_requested
    end

    context 'with some other file owner' do
      let(:file_owner) { SecureRandom.uuid }

      before do
        Stub.service(:collabspace, memberships_url: '/memberships{?user_id,status,kind,course_id}')
        Stub.request(
          :collabspace, :get, '/memberships',
          query: {user_id:, status: 'admin', kind: 'team', course_id:}
        ).to_return Stub.json([])
      end

      it 'can not be removed' do
        action
        expect(json['success']).to be_falsey
        expect(file_delete_stub).not_to have_been_requested
      end
    end

    context 'with user of same team as owner' do
      let(:team_member) { SecureRandom.uuid }
      let(:file_owner) { team_member }
      let(:learning_room_id) { SecureRandom.uuid }

      before do
        Stub.service(:collabspace, memberships_url: '/memberships{?user_id,status,kind,course_id}')
        Stub.request(
          :collabspace, :get, '/memberships',
          query: {user_id:, status: 'admin', kind: 'team', course_id:}
        ).to_return Stub.json([
          {user_id:, learning_room_id:},
        ])

        Stub.request(
          :collabspace, :get, '/memberships',
          query: {status: 'admin', learning_room_id:}
        ).to_return Stub.json([
          {user_id:},
          {user_id: team_member},
        ])
      end

      it 'can be removed' do
        action
        expect(file_delete_stub).to have_been_requested
      end
    end
  end
end
