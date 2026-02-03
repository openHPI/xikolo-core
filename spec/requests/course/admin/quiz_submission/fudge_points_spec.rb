# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz submissions: Grant fudge points', type: :request do
  subject(:grant_points) do
    post "/courses/#{course['id']}/add_fudge_points",
      params:,
      headers: {'HTTP_AUTHORIZATION' => "Xikolo-Session session_id=#{stub_session_id}", 'Referer' => '/previous'}
  end

  let(:submission_id) { '7d689603-ad14-4d8b-917f-318e118bf066' }
  let(:fudge_points) { 1.5 }
  let(:course) { build(:'course:course') }

  before do
    Stub.request(
      :course, :get, "/courses/#{course['id']}"
    ).to_return Stub.json(course)

    Stub.request(
      :quiz, :get, "/quiz_submissions/#{submission_id}"
    ).to_return Stub.json(build(:'quiz:submission', fudge_points:))
    Stub.request(
      :quiz, :patch, "/quiz_submissions/#{submission_id}",
      body: {fudge_points:}
    ).to_return Stub.response(status: 200)

    stub_user_request permissions: ['quiz.submission.manage']
  end

  describe 'response' do
    let(:json) { response.parsed_body }
    let(:user_id) { '00000001-3100-4444-9999-000000000002' }

    context 'when we send correct parameters' do
      let(:params) { {fudge_points:, id: submission_id} }

      it 'redirects back with a success message' do
        grant_points
        expect(response).to redirect_to '/previous'
        expect(flash[:success].first).to eq('The grading was updated.')
      end
    end

    context 'when we lose points in parameters' do
      let(:params) { {id: submission_id} }

      it 'redirects back with an error message' do
        grant_points
        expect(response).to redirect_to '/previous'
        expect(flash[:error].first).to eq('The grading could not be updated.')
      end
    end
  end
end
