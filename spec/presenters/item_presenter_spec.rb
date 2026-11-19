# frozen_string_literal: true

require 'spec_helper'

describe ItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new item: item_resource, course: course, section: section_resource, user: current_user
  end

  let(:item) { create(:item, section_id: section.id) }
  let(:item_resource) { build(:'course:item', id: item.id, content_type: item.content_type, open_mode: item.open_mode, **additional_item_params) }
  let(:additional_item_params) { {} }
  let(:course) { create(:course, course_code: 'test', pinboard_enabled:, forum_is_locked:) }
  let(:pinboard_enabled) { true }
  let(:forum_is_locked) { false }
  let(:section_resource) { build(:'course:section', id: section.id, course: section.course_id) }
  let(:section) { create(:section, course:) }
  let(:anonymous) { CurrentUser::AnonymousUser.new(context_id: 'root') }
  let(:permissions) { ['course.content.access.available'] }
  let(:user) do
    CurrentUser::User.new(
      session: create(:'account_service/session'),
      context_id: 'root'
    )
  end
  let(:current_user) { user }

  before do
    role = create(:'account_service/role', permissions: permissions)
    create(:'account_service/grant', principal: user.session.user, role:)
  end

  describe '#unlocked?' do
    context 'without start and end dates' do
      let(:additional_item_params) { {effective_start_date: nil, end_date: nil, effective_end_date: nil} }

      it { is_expected.to be_unlocked }
    end

    context 'with a start date in the future' do
      let(:additional_item_params) { {effective_start_date: 2.days.from_now.iso8601(3)} }

      it { is_expected.not_to be_unlocked }
    end

    context 'with a start date in the past' do
      let(:additional_item_params) { {effective_start_date: 2.days.ago.iso8601(3)} }

      context 'without an end date' do
        it { is_expected.to be_unlocked }
      end

      context 'with an end date in the future' do
        let(:additional_item_params) { super().merge(effective_end_date: 4.days.from_now.iso8601(3)) }

        it { is_expected.to be_unlocked }
      end

      context 'with an end date in the past' do
        let(:additional_item_params) { super().merge(effective_end_date: 1.day.ago.iso8601(3)) }

        it { is_expected.not_to be_unlocked }
      end
    end
  end

  describe '#path' do
    subject { presenter.path }

    it { is_expected.to eq "/learn/test/items/#{short_uuid(item.id)}" }
  end

  describe '#course_info' do
    subject { presenter.course_info }

    it { is_expected.to be_a CourseInfoPresenter }
  end

  describe '#locked?' do
    let(:item) { create(:item, :video, section_id: section.id, open_mode:) }
    let(:open_mode) { false }

    it { is_expected.not_to be_locked }

    context 'with an anonymous user' do
      let(:current_user) { anonymous }

      it { is_expected.to be_locked }

      context 'when the item is in open mode' do
        let(:open_mode) { true }

        it { is_expected.not_to be_locked }
      end
    end

    context 'with a non-enrolled user' do
      let(:permissions) { {} }

      it { is_expected.to be_locked }

      context 'when the item is in open mode' do
        let(:open_mode) { true }

        it { is_expected.not_to be_locked }
      end
    end
  end

  describe '#visited?' do
    context 'without a user_state' do
      it { is_expected.not_to be_visited }
    end

    context 'when the user_state is nil' do
      let(:additional_item_params) { {user_state: nil} }

      it { is_expected.not_to be_visited }
    end

    context "when the user_state is 'new'" do
      let(:additional_item_params) { {user_state: 'new'} }

      it { is_expected.not_to be_visited }
    end

    context "when the user_state is 'visited'" do
      let(:additional_item_params) { {user_state: 'visited'} }

      it { is_expected.to be_visited }
    end

    context "when the user_state is 'submitted'" do
      let(:additional_item_params) { {user_state: 'submitted'} }

      it { is_expected.to be_visited }
    end

    context "when the user_state is 'graded'" do
      let(:additional_item_params) { {user_state: 'graded'} }

      it { is_expected.to be_visited }
    end
  end

  describe '#main_exercise?' do
    context 'when the exercise_type is nil' do
      it { is_expected.not_to be_main_exercise }
    end

    context "when the exercise_type is 'main'" do
      let(:additional_item_params) { {exercise_type: 'main'} }

      it { is_expected.to be_main_exercise }
    end

    context "when the exercise_type is 'bonus'" do
      let(:additional_item_params) { {exercise_type: 'bonus'} }

      it { is_expected.not_to be_main_exercise }
    end
  end

  describe '#bonus_exercise?' do
    context 'when the exercise_type is nil' do
      it { is_expected.not_to be_bonus_exercise }
    end

    context "when the exercise_type is 'main'" do
      let(:additional_item_params) { {exercise_type: 'main'} }

      it { is_expected.not_to be_bonus_exercise }
    end

    context "when the exercise_type is 'bonus'" do
      let(:additional_item_params) { {exercise_type: 'bonus'} }

      it { is_expected.to be_bonus_exercise }
    end
  end

  describe '#exam_locked?' do
    let(:additional_item_params) { {exercise_type: 'exam', minimum_progress_percentage: 75} }

    def course_progress_with(visits_percentage_fpoints)
      create(:'course_service/course_progress', course:, user_id: current_user.id, visits_percentage_fpoints:)
    end

    context 'when the item is not an exam' do
      let(:additional_item_params) { {exercise_type: 'main'} }

      it { is_expected.not_to be_exam_locked }
    end

    context 'when the item is an exam' do
      context 'when the user has course.content.access' do
        let(:permissions) { %w[course.content.access course.content.access.available] }

        it { is_expected.not_to be_exam_locked }
      end

      context 'with an anonymous user' do
        let(:current_user) { anonymous }

        it { is_expected.to be_exam_locked }
      end

      context 'without a user' do
        let(:current_user) { nil }

        it { is_expected.to be_exam_locked }
      end

      context 'without a course progress' do
        it { is_expected.to be_exam_locked }
      end

      context 'with a course progress' do
        context 'below the minimum progress' do
          before { course_progress_with(74_00) }

          it { is_expected.to be_exam_locked }
        end

        context 'at the minimum progress' do
          before { course_progress_with(75_00) }

          it { is_expected.not_to be_exam_locked }
        end

        context 'above the minimum progress' do
          before { course_progress_with(76_00) }

          it { is_expected.not_to be_exam_locked }
        end
      end

      context 'without a minimum progress percentage' do
        let(:additional_item_params) { {exercise_type: 'exam', minimum_progress_percentage: nil} }

        context 'below the default progress' do
          before { course_progress_with(74_00) }

          it { is_expected.to be_exam_locked }
        end

        context 'at the default progress' do
          before { course_progress_with(75_00) }

          it { is_expected.not_to be_exam_locked }
        end
      end
    end
  end

  describe '#course_pinboard_closed?' do
    it 'has an unlocked course forum by default' do
      expect(presenter).not_to be_course_pinboard_closed
    end

    context 'with an unlocked course forum' do
      let(:forum_is_locked) { false }

      it { is_expected.not_to be_course_pinboard_closed }
    end

    context 'with a locked course forum' do
      let(:forum_is_locked) { true }

      it { is_expected.to be_course_pinboard_closed }
    end
  end

  describe '#course_pinboard?' do
    it 'is enabled by default' do
      expect(presenter).to be_course_pinboard
    end

    context 'with a disabled pinboard' do
      let(:pinboard_enabled) { false }

      it 'is disabled' do
        expect(presenter).not_to be_course_pinboard
      end
    end
  end
end
