# frozen_string_literal: true

require 'spec_helper'

describe 'Chatbot Bridge API: Courses: Create', type: :request do
  subject(:request) do
    post "/bridges/chatbot/my_courses/#{params[:id]}", headers:, params:
  end

  let(:user_id) { generate(:user_id) }
  let(:token) { "Bearer #{TokenSigning.for(:chatbot).sign(user_id)}" }
  let(:headers) { {'Authorization' => token} }
  let(:json) { JSON.parse response.body }
  let(:course) { build(:'course:course') }
  let(:params) { {user_id:, id: course['id']} }
  let(:stub_enrollment) do
    Stub.request(
      :course, :post, '/enrollments',
      body: hash_including(user_id:, course_id: params[:id])
    ).to_return Stub.response(status: 201)
  end

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(:course, :get, "/courses/#{params[:id]}").to_return Stub.json(course)
    stub_enrollment
    request
  end

  it 'enrolls a user to the specific course' do
    expect(response).to have_http_status :ok
    expect(stub_enrollment).to have_been_requested
  end

  context 'enrolling to invite-only courses' do
    let(:course) { super().merge(invite_only: true) }

    it 'throws error forbidden and does not enroll a user to this course' do
      expect(response).to have_http_status :forbidden
      expect(stub_enrollment).not_to have_been_requested
    end
  end
end
