# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz submissions: Grant additional attempt', type: :request do
  subject(:grant_attempt) do
    post "/courses/#{course['id']}/add_attempt",
      headers: {'HTTP_AUTHORIZATION' => "Xikolo-Session session_id=#{stub_session_id}"},
      params: {user_id:, quiz_id:}
  end

  let(:quiz_id) { '00000001-3800-4444-9999-000000000004' }
  let(:user_id) { '00000001-3100-4444-9999-000000000002' }
  let(:course) { build(:'course:course') }

  before do
    Stub.request(
      :course, :get, "/courses/#{course['id']}"
    ).to_return Stub.json(course)

    stub_user_request permissions: ['quiz.submission.grant_attempt']
  end

  describe 'response' do
    let!(:quiz_attempt_request) do
      Stub.request(
        :quiz, :post, '/user_quiz_attempts',
        body: {user_id:, quiz_id:}
      ).to_return Stub.response(status: 200)
    end

    it 'returns correct HTTP status' do
      grant_attempt
      expect(response).to redirect_to '/'
    end

    it 'sends the data to xi-quiz' do
      grant_attempt
      expect(quiz_attempt_request).to have_been_requested
    end
  end
end
