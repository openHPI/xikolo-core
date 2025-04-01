# frozen_string_literal: true

require 'spec_helper'

describe 'Course: Learning Evaluation: Trigger Recalculation', type: :request do
  subject(:creation) do
    api.rel(:course_learning_evaluation).post({}, params: {course_id: course.id}).value!
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:course) { create(:course, :with_content_tree, progress_calculated_at: 1.week.ago) }

  context 'with the course not requiring progress recalculation' do
    before { course.node.update!(progress_stale_at: 2.weeks.ago) }

    it { is_expected.to respond_with :created }

    it 'does not trigger the recalculation' do
      expect { creation }.not_to change(LearningEvaluation::PersistForCourseWorker.jobs, :size)
    end
  end

  context 'with the course marked for progress recalculation' do
    before { course.node.update!(progress_stale_at: 1.day.ago) }

    it { is_expected.to respond_with :created }

    it 'triggers the recalculation' do
      expect { creation }.to change(LearningEvaluation::PersistForCourseWorker.jobs, :size).from(0).to(1)
    end

    it 'marks the course progress as recalculated' do
      expect do
        Sidekiq::Testing.inline! { creation }
      end.to change { course.reload.needs_recalculation? }.from(true).to(false)
    end
  end

  context 'for a legacy course' do
    let(:course) { create(:course) }

    it { is_expected.to respond_with :created }

    it 'triggers the recalculation' do
      expect { creation }.to change(LearningEvaluation::PersistForCourseWorker.jobs, :size).from(0).to(1)
    end

    it 'marks the course progress as recalculated' do
      expect do
        Sidekiq::Testing.inline! { creation }
      end.to change { course.reload.needs_recalculation? }.from(true).to(false)
    end
  end

  context 'with sections requiring progress recalculation' do
    before do
      create_list(:section, 3, course:)
      course.sections.first.node.update!(progress_stale_at: 1.day.ago)
      course.node.update!(progress_stale_at: 1.day.ago)
    end

    it { is_expected.to respond_with :created }

    it 'triggers the recalculation' do
      expect { creation }.to change(LearningEvaluation::PersistForCourseWorker.jobs, :size).from(0).to(1)
    end

    it 'marks the section and course progresses as recalculated' do
      Sidekiq::Testing.inline! { creation }

      expect(course.sections.first.reload.node.needs_recalculation?).to be false
      expect(course.reload.needs_recalculation?).to be false
    end
  end

  context 'with the course recently recalculated' do
    let(:course) { create(:course, :with_content_tree, progress_calculated_at: 50.minutes.ago) }

    it 'does not trigger the recalculation' do
      expect { creation }.not_to change(LearningEvaluation::PersistForCourseWorker.jobs, :size)
    end
  end

  context 'with the legacy course recently recalculated' do
    let(:course) { create(:course, progress_calculated_at: 50.minutes.ago) }

    it 'does not trigger the recalculation' do
      expect { creation }.not_to change(LearningEvaluation::PersistForCourseWorker.jobs, :size)
    end
  end
end
