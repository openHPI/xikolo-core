# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Achievements::RecordOfAchievement, type: :model do
  variant 'With dynamic learning evaluation' do
    let(:evaluation) do
      CourseService::LearningEvaluation::Dynamic.new.call(
        CourseService::Enrollment.where(course:, user_id:)
      ).take
    end
  end

  variant 'With persisted learning evaluation' do
    let(:evaluation) do
      CourseService::CourseProgress.find_by(course:, user_id:)
    end
  end

  subject(:roa) { described_class.new(course, evaluation) }

  let(:course) { create(:'course_service/course', :active, course_params) }
  let(:course_params) { {cop_enabled: true, roa_enabled: true, on_demand: false} }
  let(:user_id) { enrollment.user_id }
  let(:enrollment) { create(:'course_service/enrollment', enrollment_params) }
  let(:enrollment_params) { {course:} }
  let!(:item) { create(:'course_service/item', :homework, :with_max_points, item_params) }
  let(:item_params) { {section: create(:'course_service/section', course:)} }

  around do |example|
    Sidekiq::Testing.inline!(&example)
  end

  with_all do
    context 'and there is no RoA for the course' do
      let(:course_params) { super().merge(roa_enabled: false) }

      it { is_expected.not_to be_achieved }
      it { is_expected.not_to be_achievable }
    end

    context 'and the user has qualified for the RoA' do
      let(:dpoints) { 8 }
      let(:result) do
        create(:'course_service/result', item:, user_id:, dpoints:)
      end

      before { result }

      context '(not yet released)' do
        let(:course_params) { super().merge(records_released: false, end_date: 2.weeks.from_now) }

        it { is_expected.to be_achieved }
        it { is_expected.not_to be_achievable }
        it { is_expected.not_to be_released }

        context 'by reaching the exact threshold' do
          let(:dpoints) { 5 }

          it { is_expected.to be_achieved }
          it { is_expected.not_to be_achievable }
          it { is_expected.not_to be_released }
        end
      end

      context '(released)' do
        let(:course_params) { super().merge(records_released: true, end_date: 2.weeks.from_now) }

        it { is_expected.to be_achieved }
        it { is_expected.not_to be_achievable }
        it { is_expected.to be_released }
      end

      context 'after course end' do
        let(:course_params) { super().merge(status: 'archive', end_date: 1.week.ago) }

        it { is_expected.to be_achieved }
        it { is_expected.not_to be_achievable }

        context 'with course reactivation' do
          let(:course_params) { super().merge(on_demand: true) }
          let(:enrollment_params) { super().merge(forced_submission_date: 3.weeks.from_now) }

          it { is_expected.to be_achieved }
          it { is_expected.not_to be_achievable }
        end
      end

      context 'in course running forever' do
        let(:course_params) { super().merge(end_date: nil) }
        let(:item_params) { super().merge(submission_deadline: nil) }

        it { is_expected.to be_achieved }
        it { is_expected.not_to be_achievable }
      end

      context 'with optional item for achieving the RoA threshold' do
        let(:course_params) { super().merge(end_date: nil) }
        let(:item_params) { super().merge(optional: true) }

        it { is_expected.to be_achieved }
        it { is_expected.not_to be_achievable }
      end

      context 'with a self-test as the latest result' do
        let(:course_params) { super().merge(end_date: nil) }
        let(:result) do
          create(:'course_service/result', item:, user_id:, dpoints:, created_at: 1.day.ago)
        end

        before do
          selftest = create(:'course_service/item', :quiz, :with_max_points)
          create(:'course_service/result', item: selftest, user_id:, dpoints: 8, created_at: 1.hour.ago)
        end

        it { is_expected.to be_achieved }
        it { is_expected.not_to be_achievable }
      end

      context 'with (soft-)deleted enrollment' do
        let(:enrollment_params) { super().merge(deleted: true) }

        it { is_expected.to be_achieved }
        it { is_expected.not_to be_achievable }
      end

      context 'with existing course content tree' do
        let(:course) { create(:'course_service/course', :with_content_tree, :active, course_params) }

        # Reload course structure record to recalculate tree indices.
        before { course.node.reload }

        it { is_expected.to be_achieved }
        it { is_expected.not_to be_achievable }
      end
    end

    context 'and requirements for the RoA are not fulfilled' do
      it { is_expected.not_to be_achieved }
      it { is_expected.to be_achievable }

      context 'with some points achieved' do
        before { create(:'course_service/result', item:, user_id:, dpoints: 2) }

        it { is_expected.not_to be_achieved }
        it { is_expected.to be_achievable }
      end

      context 'after course end' do
        let(:course_params) { super().merge(status: 'archive', end_date: 1.week.ago) }

        it { is_expected.not_to be_achieved }
        it { is_expected.not_to be_achievable }

        context 'with course reactivation' do
          let(:course_params) { super().merge(on_demand: true) }
          let(:enrollment_params) { super().merge(forced_submission_date: 4.weeks.from_now) }

          it { is_expected.not_to be_achieved }
          it { is_expected.to be_achievable }
        end
      end

      context 'in course running forever' do
        let(:course_params) { super().merge(end_date: nil) }
        let(:item_params) { super().merge(submission_deadline: nil) }

        it { is_expected.not_to be_achieved }
        it { is_expected.to be_achievable }
      end

      context 'with sufficient visits for non-published items' do
        let(:item_params) { super().merge(published: false) }

        before { create(:'course_service/result', item:, user_id: generate(:user_id), dpoints: 8) }

        it { is_expected.not_to be_achieved }
        it { is_expected.to be_achievable }
      end

      context 'with sufficient points by another user' do
        before { create(:'course_service/result', item:, user_id: generate(:user_id), dpoints: 8) }

        it { is_expected.not_to be_achieved }
        it { is_expected.to be_achievable }
      end
    end

    context 'when the user is not enrolled' do
      let(:user_id) { generate(:user_id) }

      it { is_expected.not_to be_achieved }
      it { is_expected.not_to be_achievable }
    end
  end
end
