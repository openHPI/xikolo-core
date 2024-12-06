# frozen_string_literal: true

require 'spec_helper'

describe 'Quiz submissions: Exclude from proctoring', type: :request do
  subject(:exclude) do
    post "/courses/#{course.id}/exclude_from_proctoring",
      headers: {'HTTP_AUTHORIZATION' => "Xikolo-Session session_id=#{stub_session_id}", 'Referer' => '/previous'},
      params: {id: submission['id']}
  end

  let(:submission) { build(:'quiz:submission', id: '00000001-3800-4444-9999-000000000008', quiz_id: '00000001-3800-4444-9999-000000000004', course_id: course.id) }
  let(:course) { create(:course) }
  let(:course_resource) { build(:'course:course', id: course.id, course_code: course.course_code) }

  let!(:smowl_stub) do
    stub_request(:post, 'https://results-api.smowltech.net/index.php/Restv1/Disable_Submission')
      .with(body: 'entity=SampleEntity&password=samplepassword&modality=quiz&idActivity=21zXlizr0SbnQGwzW_21zXlizr0SbnQGwA0')
      .to_return Stub.json({Disable_SubmissionResponse: {ack: smowl_ack}})
  end

  before do
    stub_user_request permissions: ['quiz.submission.manage.proctoring']

    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, "/courses/#{course.id}"
    ).to_return Stub.json(course_resource)

    Stub.service(:quiz, build(:'quiz:root'))
    Stub.request(
      :quiz, :get, "/quiz_submissions/#{submission['id']}"
    ).to_return Stub.json(submission)
  end

  context 'success' do
    let(:smowl_ack) { true }

    it 'disables the submission at SMOWL' do
      exclude
      expect(smowl_stub).to have_been_requested
    end

    it 'returns JSON for a successful response' do
      exclude
      expect(response).to redirect_to '/previous'
      expect(flash[:success].first).to eq 'Submission successfully excluded from proctoring.'
    end
  end

  context 'failure' do
    let(:smowl_ack) { false }

    it 'tries to disable the submission at SMOWL' do
      exclude
      expect(smowl_stub).to have_been_requested
    end

    it 'redirects back with a failure message' do
      exclude
      expect(response).to redirect_to '/previous'
      expect(flash[:error].first).to eq 'Submission exclusion failed.'
    end
  end
end
