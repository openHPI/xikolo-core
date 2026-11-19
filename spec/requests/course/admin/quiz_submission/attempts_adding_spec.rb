# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz submissions: Grant additional attempt', type: :request do
  subject(:grant_attempt) do
    post "/learn/#{course['id']}/add_attempt",
      params: {user_id:, quiz_id:}
  end

  let(:quiz_id) { '00000001-3800-4444-9999-000000000004' }
  let(:user_id) { '00000001-3100-4444-9999-000000000002' }
  let(:course) { create(:'course_service/course') }
  let(:user) { create(:'account_service/user') }

  before do
    course

    sign_in(user:)
    role = create(:'account_service/role', permissions: ['quiz.submission.grant_attempt'])
    create(:'account_service/grant', principal: user, role:)
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
