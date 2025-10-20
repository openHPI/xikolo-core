# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LearningEvaluation::UpdateCourseProgressWorker, type: :worker do
  subject(:perform) do
    Sidekiq::Testing.inline! do
      described_class.perform_async(course.id, user_id)
    end
  end

  let(:course) { create(:'course_service/course') }
  let(:user_id) { 'f03a00d1-bbad-40c9-972c-cb69e238af5c' }

  context 'without persisted_learning_evaluation config' do
    before do
      xi_config <<~YML
        persisted_learning_evaluation: false
      YML
    end

    describe '#perform' do
      it 'generates no course progress' do
        expect { perform }.not_to change(CourseProgress, :count)
      end
    end
  end

  context 'with persisted_learning_evaluation config' do
    before do
      xi_config <<~YML
        persisted_learning_evaluation: true
      YML
    end

    describe '#perform' do
      it 'generates a course progress' do
        expect { perform }.to change(CourseProgress, :count).from(0).to(1)
      end
    end
  end
end
