# frozen_string_literal: true

require 'spec_helper'

describe QuizService::ReportQuizResultsJob, type: :job do
  subject(:work) { job.perform(submission_id) }

  let(:job) { described_class.new }
  let(:submission_id) { SecureRandom.uuid }
  let(:quiz_submission) { instance_double(QuizService::QuizSubmission) }

  before do
    allow(QuizService::QuizSubmission)
      .to receive(:find).with(submission_id)
      .and_return(quiz_submission)
    allow(quiz_submission)
      .to receive(:report_result!)
  end

  it 'finds the quiz submission' do
    work
    expect(QuizService::QuizSubmission).to have_received(:find).with(submission_id)
  end

  it 'reports the result' do
    work
    expect(quiz_submission).to have_received(:report_result!)
  end
end
