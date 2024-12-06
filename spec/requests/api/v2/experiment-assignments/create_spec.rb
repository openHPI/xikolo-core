# frozen_string_literal: true

require 'spec_helper'

describe 'APIv2: Create experiment assignment', type: :request do
  subject(:request) do
    post '/api/v2/experiment-assignments/', params: post_data, headers:
  end

  let(:base_headers) { {Content_Type: 'application/vnd.api+json'} }
  let(:authorization_headers) { {} }
  let(:headers) { base_headers.merge(authorization_headers) }

  let(:stub_session_id) { "token=#{SecureRandom.hex(16)}" }
  let(:user_id) { generate(:user_id) }

  let(:test_identifier) { 'new_test' }
  let(:attributes) { {identifier: test_identifier} }
  let(:relationships) { {} }
  let(:post_data) do
    {
      data: {
        type: 'experiment-assignments',
        attributes:,
        relationships:,
      },
    }
  end

  before do
    Stub.service(:grouping, user_assignments_url: '/user_assignment')
    Stub.service(:account, session_url: '/sessions/{id}')
    api_stub_user id: user_id
  end

  context 'for authenticated users' do
    let(:authorization_headers) { {Authorization: "Legacy-Token #{stub_session_id}"} }

    let(:assignment_body) { {} }
    let!(:assignment_stub) do
      Stub.request(
        :grouping, :post, '/user_assignment',
        query: {user_id:}, body: assignment_body
      ).to_return Stub.json({features: {'grouping.new_test': '3'}})
    end

    context 'with a course' do
      let(:course_id) { SecureRandom.uuid }
      let(:relationships) do
        {
          course: {
            data: {
              type: 'courses',
              id: course_id,
            },
          },
        }
      end
      let(:assignment_body) { {identifier: test_identifier, course_id:} }

      it 'responds successfully' do
        request
        expect(response).to have_http_status :created
      end

      it 'creates the user assignment' do
        request
        expect(assignment_stub).to have_been_requested
      end
    end

    context 'without a course' do
      let(:assignment_body) { {identifier: test_identifier} }

      it 'responds successfully' do
        request
        expect(response).to have_http_status :created
      end

      it 'creates the user assignment' do
        request
        expect(assignment_stub).to have_been_requested
      end
    end

    context 'without an identifier' do
      let(:attributes) { {foo: 'bar'} }

      it 'responds successfully' do
        request
        expect(response).to have_http_status :bad_request
      end

      it 'creates the user assignment' do
        request
        expect(assignment_stub).not_to have_been_requested
      end
    end
  end

  context 'for anonymous users' do
    it 'responds with Unauthorized' do
      request
      expect(response).to have_http_status :unauthorized
    end
  end
end
