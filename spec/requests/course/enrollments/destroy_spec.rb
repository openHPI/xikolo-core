# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Enrollments: Destroy', type: :request do
  subject(:action) do
    delete "/enrollments/#{enrollment['id']}", headers:
  end

  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:user_id) { enrollment['user_id'] }
  let(:enrollment) { build(:'course:enrollment') }
  let(:delete_stub) do
    Stub.request(
      :course, :delete, "/enrollments/#{enrollment['id']}"
    ).to_return Stub.json({}, status: 204)
  end

  before do
    stub_user_request id: user_id
    Stub.request(
      :course, :get, "/enrollments/#{enrollment['id']}"
    ).to_return Stub.json(
      enrollment.merge(url: "/course_service/enrollments/#{enrollment['id']}")
    )

    delete_stub
  end

  it 'redirects to the dashboard' do
    action
    expect(response).to redirect_to dashboard_path
  end

  it 'deletes the enrollment' do
    action
    expect(delete_stub).to have_been_requested
  end

  context 'for another user\'s enrollment' do
    let(:user_id) { generate(:user_id) }

    it 'redirects to the homepage' do
      action
      expect(response).to redirect_to root_url
    end

    it 'does not delete the enrollment' do
      action
      expect(delete_stub).not_to have_been_requested
    end
  end
end
