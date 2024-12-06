# frozen_string_literal: true

require 'spec_helper'

describe UnlockCourseAssignmentsWorker, type: :worker do
  subject(:work) { worker.perform course_id, user_id }

  let(:worker) { UnlockCourseAssignmentsWorker.new }

  let(:course_id) { SecureRandom.uuid }
  let(:user_id)   { SecureRandom.uuid }

  let(:attempts_handler) { instance_double(AttemptsHandler) }

  before do
    allow(AttemptsHandler)
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
