# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CourseService::LearningEvaluation::UpdateCourseProgressJob, type: :job do
  subject(:perform) do
    perform_enqueued_jobs do
      described_class.perform_later(course.id, user_id)
    end
  end

  let(:course) { create(:'course_service/course') }
  let(:user_id) { 'f03a00d1-bbad-40c9-972c-cb69e238af5c' }

  describe '#perform' do
    it 'generates a course progress' do
      expect { perform }.to change(CourseService::CourseProgress, :count).from(0).to(1)
    end
  end
end
