# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz submissions: Grant fudge points', type: :request do
  subject(:grant_points) do
    post "/learn/#{course.id}/add_fudge_points",
      params:,
      headers: {'Referer' => '/previous'}
  end

  let(:quiz) { create(:'quiz_service/quiz') }
  let(:submission) do
    create(:'quiz_service/quiz_submission',
      quiz:,
      user_id: user.id,
      course_id: course.id,
      quiz_submission_time: 1.hour.ago,
      fudge_points:)
  end
  let(:fudge_points) { 1.5 }
  let(:course) { create(:'course_service/course') }
  let(:user) { create(:'account_service/user') }

  before do
    sign_in(user:)
    role = create(:'account_service/role', permissions: ['quiz.submission.manage'])
    create(:'account_service/grant', principal: user, role:)
  end

  describe 'response' do
    let(:json) { response.parsed_body }
    let(:user_id) { '00000001-3100-4444-9999-000000000002' }

    context 'when we send correct parameters' do
      let(:params) { {fudge_points:, id: submission.id} }

      it 'redirects back with a success message' do
        grant_points
        expect(response).to redirect_to '/previous'
        expect(flash[:success].first).to eq('The grading was updated.')
      end
    end

    context 'when we lose points in parameters' do
      let(:params) { {id: submission.id} }

      it 'redirects back with an error message' do
        grant_points
        expect(response).to redirect_to '/previous'
        expect(flash[:error].first).to eq('The grading could not be updated.')
      end
    end
  end
end
