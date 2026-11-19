# frozen_string_literal: true

require 'spec_helper'

describe QuizService::UnlockCourseAssignmentsJob, type: :job do
  subject(:work) { job.perform course_id, user_id }

  let(:job) { described_class.new }

  let(:course_id) { SecureRandom.uuid }
  let(:user_id)   { SecureRandom.uuid }

  let(:attempts_handler) { instance_double(QuizService::AttemptsHandler) }

  before do
    allow(QuizService::AttemptsHandler)
      .to receive(:new).with(course_id, user_id)
      .and_return(attempts_handler)
    allow(attempts_handler)
      .to receive(:unlock_assignments)
  end

  it 'calls AttemptsHandler' do
    work
    expect(attempts_handler)
      .to have_received(:unlock_assignments)
  end
end
