# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Achievements::ConfirmationOfParticipation, type: :model do
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

  subject(:cop) { described_class.new(course, evaluation) }

  let(:course) { create(:'course_service/course', :active, course_params) }
  let(:course_params) { {cop_enabled: true, roa_enabled: true} }
  let(:user_id) { enrollment.user_id }
  let(:enrollment) { create(:'course_service/enrollment', course:) }
  let(:item_params) { {section: create(:'course_service/section', course:), published: true, optional: false} }

  before { create(:'course_service/item', item_params) }

  around do |example|
    Sidekiq::Testing.inline!(&example)
  end

  with_all do
    context 'and there is no CoP for the course' do
      let(:course_params) { super().merge(cop_enabled: false) }

      it { is_expected.not_to be_achieved }
      it { is_expected.not_to be_achieved_via_roa }
      it { is_expected.not_to be_achievable }
    end

    context 'and the user has qualified for the CoP' do
      let(:item4) { create(:'course_service/item', item_params) }
      let(:visit) { create(:'course_service/visit', item: item4, user_id:, created_at: 5.minutes.ago) }

      before do
        create(:'course_service/item', item_params)
        item3 = create(:'course_service/item', item_params)
        create(:'course_service/visit', item: item3, user_id:, created_at: 10.minutes.ago)
        item4
        visit
      end

      context '(not yet released)' do
        let(:course_params) { super().merge(records_released: false, end_date: 2.weeks.from_now) }

        it { is_expected.to be_achieved }
        it { is_expected.not_to be_achievable }
        it { is_expected.not_to be_released }
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

    context 'and requirements for the CoP are not fulfilled' do
      it { is_expected.not_to be_achieved }
      it { is_expected.not_to be_achieved_via_roa }
      it { is_expected.to be_achievable }

      context 'with some items visited' do
        before do
          create_list(:'course_service/item', 2, item_params)
          item4 = create(:'course_service/item', item_params)
          create(:'course_service/visit', item: item4, user_id:, created_at: 5.minutes.ago)
        end

        it { is_expected.not_to be_achieved }
        it { is_expected.not_to be_achieved_via_roa }
        it { is_expected.to be_achievable }
      end

      context 'with sufficient visits for optional items' do
        before do
          items = create_list(:'course_service/item', 2, item_params.merge(optional: true))
          items.each do |item|
            create(:'course_service/visit', item:, user_id:, created_at: 5.minutes.ago)
          end
        end

        it { is_expected.not_to be_achieved }
        it { is_expected.not_to be_achieved_via_roa }
        it { is_expected.to be_achievable }
      end

      context 'with sufficient visits for non-published items' do
        before do
          items = create_list(:'course_service/item', 2, item_params.merge(published: false))
          items.each do |item|
            create(:'course_service/visit', item:, user_id:, created_at: 5.minutes.ago)
          end
        end

        it { is_expected.not_to be_achieved }
        it { is_expected.not_to be_achieved_via_roa }
        it { is_expected.to be_achievable }
      end

      context 'with sufficient visits in optional sections' do
        before do
          optional_section = create(:'course_service/section', course:, optional_section: true)

          items = create_list(:'course_service/item', 2, item_params.merge(section: optional_section))
          items.each do |item|
            create(:'course_service/visit', item:, user_id:, created_at: 5.minutes.ago)
          end
        end

        it { is_expected.not_to be_achieved }
        it { is_expected.not_to be_achieved_via_roa }
        it { is_expected.to be_achievable }
      end

      context 'with sufficient visits by another user' do
        before do
          item2 = create(:'course_service/item', item_params)
          create(:'course_service/visit', item: item2, user_id: generate(:user_id), created_at: 5.minutes.ago)
        end

        it { is_expected.not_to be_achieved }
        it { is_expected.not_to be_achieved_via_roa }
        it { is_expected.to be_achievable }
      end

      context 'but the user has qualified for the RoA' do
        # Ensure the course is running forever to set the latest result for the
        # achievement date of the RoA (instead of the course end date).
        let(:course_params) { super().merge(end_date: nil) }
        let(:item4) { create(:'course_service/item', :homework, :with_max_points, item_params) }
        let(:visit) { create(:'course_service/visit', item: item4, user_id:, created_at: 5.minutes.ago) }
        let(:result) { create(:'course_service/result', item: item4, user_id:, dpoints: 8, created_at: 2.minutes.ago) }

        before do
          create_list(:'course_service/item', 2, item_params)
          item4
          visit
          result
        end

        it { is_expected.to be_achieved_via_roa }
        it { is_expected.not_to be_achievable }
      end

      context 'after course end' do
        let(:course_params) { super().merge(status: 'archive', end_date: 1.week.ago) }

        it { is_expected.not_to be_achieved }
        it { is_expected.not_to be_achieved_via_roa }
        it { is_expected.to be_achievable }
      end
    end

    context 'when the user is not enrolled' do
      let(:user_id) { generate(:user_id) }

      it { is_expected.not_to be_achieved }
      it { is_expected.not_to be_achieved_via_roa }
      it { is_expected.not_to be_achievable }
    end
  end
end
