# frozen_string_literal: true

require 'spec_helper'

describe ItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new item: item_resource, course: course_resource, section: section_resource, user: current_user
  end

  let(:item) { create(:item, section_id: section.id) }
  let(:item_resource) { build(:'course:item', id: item.id, content_type: item.content_type, open_mode: item.open_mode, **additional_item_params) }
  let(:additional_item_params) { {} }
  let(:course) { create(:course, course_code: 'test') }
  let(:course_resource) { Xikolo::Course::Course.new(id: course.id, course_code: course.course_code, **additional_course_params) }
  let(:additional_course_params) { {} }
  let(:section_resource) { build(:'course:section', id: section.id, course: section.course_id) }
  let(:section) { create(:section, course:) }
  let(:anonymous) { Xikolo::Common::Auth::CurrentUser.from_session({}) }
  let(:permissions) { ['course.content.access.available'] }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => permissions,
      'features' => {},
      'user' => {'anonymous' => false},
      'masqueraded' => false
    )
  end
  let(:current_user) { user }

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

    it { is_expected.to eq "/courses/test/items/#{short_uuid(item.id)}" }
  end

  describe '#css_classes' do
    subject(:css_classes) { presenter.css_classes }

    let(:item) { create(:item, :video, section_id: section.id) }

    context 'when the item is neither active nor visited' do
      it 'contains only the content type' do
        expect(css_classes).to eq 'video'
      end
    end

    context 'when the item was visited' do
      let(:additional_item_params) { {user_state: 'visited'} }

      it 'contains the content type and the visited status' do
        expect(css_classes.split).to contain_exactly 'video', 'visited'
      end
    end

    context 'with an active visited item' do
      let(:additional_item_params) { {user_state: 'visited'} }

      before do
        presenter.active!
      end

      it 'contains the content type and the locked and visited status' do
        expect(css_classes.split).to contain_exactly 'video', 'visited', 'active'
      end
    end

    context 'with an anonymous user' do
      let(:current_user) { anonymous }

      context 'when the item is in open mode' do
        let(:item) { create(:item, :video, section_id: section.id, open_mode: true) }

        it 'contains only the content type' do
          expect(css_classes).to eq 'video'
        end
      end

      context 'when the item is not in open mode' do
        let(:item) { create(:item, :video, section_id: section.id, open_mode: false) }

        it 'contains the content type and the locked status' do
          expect(css_classes.split).to contain_exactly 'video', 'locked'
        end
      end
    end

    context 'with a non-enrolled user' do
      let(:permissions) { {} }

      context 'when the item is in open mode' do
        let(:item) { create(:item, :video, section_id: section.id, open_mode: true) }

        it 'contains only the content type' do
          expect(css_classes).to eq 'video'
        end
      end

      context 'when the item is not in open mode' do
        let(:item) { create(:item, :video, section_id: section.id, open_mode: false) }

        it 'contains the content type and the locked status' do
          expect(css_classes.split).to contain_exactly 'video', 'locked'
        end
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

  describe '#active?' do
    it 'is not active by default' do
      expect(presenter).not_to be_active
    end

    context 'when it was activated' do
      before { presenter.active! }

      it { is_expected.to be_active }
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

  describe '#course_pinboard_closed?' do
    it 'has an unlocked course forum by default' do
      expect(presenter).not_to be_course_pinboard_closed
    end

    context 'with an unlocked course forum' do
      let(:additional_course_params) { {forum_is_locked: false} }

      it { is_expected.not_to be_course_pinboard_closed }
    end

    context 'with a locked course forum' do
      let(:additional_course_params) { {forum_is_locked: true} }

      it { is_expected.to be_course_pinboard_closed }
    end
  end

  describe '#course_pinboard?' do
    it 'is enabled by default' do
      expect(presenter).to be_course_pinboard
    end

    context 'with a disabled pinboard' do
      let(:additional_course_params) { {pinboard_enabled: false} }

      it 'is disabled' do
        expect(presenter).not_to be_course_pinboard
      end
    end
  end

  describe '#time_effort?' do
    context 'with a default time effort' do
      let(:additional_item_params) { {time_effort: 20} }

      it { is_expected.to be_time_effort }
    end

    context 'without a default time effort' do
      it { is_expected.not_to be_time_effort }
    end
  end

  describe '#formatted_time_effort' do
    subject(:formatted_time_effort) { presenter.formatted_time_effort }

    context 'with a default time effort' do
      context 'with less than one minute' do
        let(:additional_item_params) { {time_effort: 45} }

        it 'does not use pluralization' do
          expect(formatted_time_effort).to eq '1 minute'
        end
      end

      context 'with more than one minute' do
        let(:additional_item_params) { {time_effort: 110} }

        it 'uses pluralization' do
          expect(formatted_time_effort).to eq '2 minutes'
        end
      end

      context 'with exactly one hour' do
        let(:additional_item_params) { {time_effort: 3600} }

        it 'does not use pluralization' do
          expect(formatted_time_effort).to eq '1 hour'
        end
      end

      context 'with exactly two hours' do
        let(:additional_item_params) { {time_effort: 7200} }

        it 'uses pluralization' do
          expect(formatted_time_effort).to eq '2 hours'
        end
      end

      context 'with one hour and a minute' do
        let(:additional_item_params) { {time_effort: 3620} }

        it 'does not use pluralization' do
          expect(formatted_time_effort).to eq '1 hour 1 minute'
        end
      end

      context 'with several hours and several minutes' do
        let(:additional_item_params) { {time_effort: 7280} }

        it 'uses pluralization' do
          expect(formatted_time_effort).to eq '2 hours 2 minutes'
        end
      end
    end

    context 'without a default time effort' do
      it { is_expected.to be_nil }
    end
  end
end
