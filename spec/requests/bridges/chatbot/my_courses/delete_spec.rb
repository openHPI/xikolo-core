# frozen_string_literal: true

require 'spec_helper'

describe 'Chatbot Bridge API: Courses: Delete', type: :request do
  subject(:request) do
    delete "/bridges/chatbot/my_courses/#{course_id}", headers:
  end

  let(:user_id) { generate(:user_id) }
  let(:token) { "Bearer #{TokenSigning.for(:chatbot).sign(user_id)}" }
  let(:headers) { {'Authorization' => token} }
  let(:json) { JSON.parse response.body }
  let(:enrollment_id) { '48f702d1-65e6-4aa2-acff-7594fcb0f9bd' }
  let(:course) { build(:'course:course') }
  let(:course_id) { course['id'] }
  let(:stub_get_enrollment) do
    Stub.request(
      :course, :get, '/enrollments',
      query: {
        course_id:,
        user_id:,
      }
    ).to_return Stub.json([{id: enrollment_id}])
  end
  let(:stub_delete_enrollment) do
    Stub.request(
      :course, :delete, "/enrollments/#{enrollment_id}"
    ).to_return Stub.response(status: 204)
  end

  before do
    Stub.service(:course, build(:'course:root'))
    stub_get_enrollment
    stub_delete_enrollment
    request
  end

  it 'deletes the enrollment for a user' do
    expect(response).to have_http_status :no_content
    expect(stub_delete_enrollment).to have_been_requested
  end

  context 'without an existing user enrollment' do
    let(:stub_get_enrollment) do
      Stub.request(
        :course, :get, '/enrollments',
        query: {
          course_id:,
          user_id:,
        }
      ).to_return Stub.json([])
    end

    it 'throws error not found' do
      expect(response).to have_http_status :not_found
      expect(stub_delete_enrollment).not_to have_been_requested
    end
  end
end
