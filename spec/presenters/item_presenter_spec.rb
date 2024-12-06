# frozen_string_literal: true

require 'spec_helper'

describe ItemPresenter, type: :presenter do
  subject { presenter }

  let(:presenter) { described_class.new item:, course:, section:, user: current_user }
  let(:item) { Xikolo::Course::Item.new item_params }
  let(:item_id) { SecureRandom.uuid }
  let(:item_params) { {id: item_id} }
  let(:course) { Xikolo::Course::Course.new course_params }
  let(:course_params) { {id: SecureRandom.uuid, course_code: 'test'} }
  let(:section) { Xikolo::Course::Section.new section_params }
  let(:section_params) { {id: SecureRandom.uuid, course_id: course.id} }
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

  describe '#path' do
    subject { super().path }

    it { is_expected.to eq "/courses/test/items/#{short_uuid(item_id)}" }
  end

  context 'css_classes' do
    subject { super().css_classes.split }

    let(:item_params) { super().merge content_type: 'video' }

    context 'without visit or active item' do
      it { is_expected.to eq ['video'] }
    end

    context 'with visited item' do
      let(:item_params) { super().merge user_state: 'visited' }

      it { is_expected.to match_array(%w[video visited]) }
    end

    context 'with active item' do
      let(:item_params) { super().merge user_state: 'visited' }

      before do
        presenter.active!
      end

      it { is_expected.to match_array(%w[video visited active]) }
    end

    context 'anonymous user' do
      let(:current_user) { anonymous }

      context 'video item with open mode' do
        let(:item_params) { {id: item_id, content_type: 'video', open_mode: true} }

        it { is_expected.to contain_exactly('video') }
      end

      context 'video_item without open mode' do
        let(:item_params) { {id: item_id, content_type: 'video', open_mode: false} }

        it { is_expected.to match_array(%w[video locked]) }
      end
    end

    context 'non-enrolled user' do
      let(:permissions) { {} }

      context 'video item with open mode' do
        let(:item_params) { {id: item_id, content_type: 'video', open_mode: true} }

        it { is_expected.to contain_exactly('video') }
      end

      context 'video_item without open mode' do
        let(:item_params) { {id: item_id, content_type: 'video', open_mode: false} }

        it { is_expected.to match_array(%w[video locked]) }
      end
    end
  end

  context 'visited?' do
    context 'without user_state' do
      it { is_expected.not_to be_visited }
    end

    context 'with nil user_state' do
      let(:item_params) { super().merge user_state: nil }

      it { is_expected.not_to be_visited }
    end

    context 'with new user_state' do
      let(:item_params) { super().merge user_state: 'new' }

      it { is_expected.not_to be_visited }
    end

    context 'with visited user_state' do
      let(:item_params) { super().merge user_state: 'visited' }

      it { is_expected.to be_visited }
    end

    context 'with submitted user_state' do
      let(:item_params) { super().merge user_state: 'submitted' }

      it { is_expected.to be_visited }
    end

    context 'with graded user_state' do
      let(:item_params) { super().merge user_state: 'graded' }

      it { is_expected.to be_visited }
    end
  end

  context 'active?' do
    context 'by default' do
      it { is_expected.not_to be_active }
    end

    context 'after it was activated' do
      before { presenter.active! }

      it { is_expected.to be_active }
    end
  end

  context 'main_exercise?' do
    context 'with exercise_type is nil' do
      let(:item_params) { super().merge exercise_type: nil }

      it { is_expected.not_to be_main_exercise }
    end

    context 'with exercise_type is main' do
      let(:item_params) { super().merge exercise_type: 'main' }

      it { is_expected.to be_main_exercise }
    end

    context 'with exercise_type is bonus' do
      let(:item_params) { super().merge exercise_type: 'bonus' }

      it { is_expected.not_to be_main_exercise }
    end
  end

  context 'bonus_exercise?' do
    context 'with exercise_type is nil' do
      let(:item_params) { super().merge exercise_type: nil }

      it { is_expected.not_to be_bonus_exercise }
    end

    context 'with exercise_type is main' do
      let(:item_params) { super().merge exercise_type: 'main' }

      it { is_expected.not_to be_bonus_exercise }
    end

    context 'with exercise_type is bonus' do
      let(:item_params) { super().merge exercise_type: 'bonus' }

      it { is_expected.to be_bonus_exercise }
    end
  end

  context 'section_pinboard_closed?' do
    context 'by default' do
      it { is_expected.not_to be_section_pinboard_closed }
    end

    context 'with unlocked section forum' do
      let(:section_params) { super().merge pinboard_closed: false }

      it { is_expected.not_to be_section_pinboard_closed }
    end

    context 'with locked section forum' do
      let(:section_params) { super().merge pinboard_closed: true }

      it { is_expected.to be_section_pinboard_closed }
    end
  end

  context 'course_pinboard_closed?' do
    subject { presenter.course_pinboard_closed? }

    context 'by default' do
      it { is_expected.to be_nil }
    end

    context 'with unlocked course forum' do
      let(:course_params) { super().merge forum_is_locked: false }

      it { is_expected.to be_falsy }
    end

    context 'with locked course forum' do
      let(:course_params) { super().merge forum_is_locked: true }

      it { is_expected.to be_truthy }
    end
  end

  describe '#course_pinboard?' do
    it 'is enabled by default' do
      expect(presenter).to be_course_pinboard
    end

    context 'with disabled pinboard' do
      let(:course_params) { super().merge(pinboard_enabled: false) }

      it 'is disabled' do
        expect(presenter).not_to be_course_pinboard
      end
    end
  end

  context 'time_effort?' do
    subject { presenter.time_effort? }

    context 'w/ default time effort' do
      let(:item_params) { super().merge(time_effort: 20) }

      it { is_expected.to be true }
    end

    context 'w/o default time effort' do
      it { is_expected.to be false }
    end
  end

  context 'formatted_time_effort' do
    subject { presenter.formatted_time_effort }

    context 'w/ default time effort' do
      context 'less than one minute' do
        let(:item_params) { super().merge(time_effort: 45) }

        it { is_expected.to eq '1 minute' }
      end

      context 'more than one minute (pluralization)' do
        let(:item_params) { super().merge(time_effort: 110) }

        it { is_expected.to eq '2 minutes' }
      end

      context 'exactly one hour' do
        let(:item_params) { super().merge(time_effort: 3600) }

        it { is_expected.to eq '1 hour' }
      end

      context 'exactly two hours' do
        let(:item_params) { super().merge(time_effort: 7200) }

        it { is_expected.to eq '2 hours' }
      end

      context 'more than one hour' do
        let(:item_params) { super().merge(time_effort: 3620) }

        it { is_expected.to eq '1 hour 1 minute' }
      end

      context 'more than one hour (pluralization)' do
        let(:item_params) { super().merge(time_effort: 7280) }

        it { is_expected.to eq '2 hours 2 minutes' }
      end
    end

    context 'w/o default time effort' do
      it { is_expected.to be_nil }
    end
  end
end
