# frozen_string_literal: true

require 'spec_helper'

describe LtiExerciseItemPresenter, type: :presenter do
  subject { presenter }

  let(:exercise) { create(:lti_exercise) }
  let(:gradebook) { create(:lti_gradebook, exercise:, user_id:) }

  let(:presenter) { described_class.new item:, course:, section:, user: }
  let(:item) { build(:'course:item', **item_params) }
  let(:item_id) { SecureRandom.uuid }
  let(:item_params) { {id: item_id, content_id: exercise.id, max_points: 5.0} }
  let(:course) { Xikolo::Course::Course.new course_params }
  let(:course_params) { {id: SecureRandom.uuid, course_code: 'test'} }
  let(:section) { Xikolo::Course::Section.new section_params }
  let(:section_params) { {id: SecureRandom.uuid, course_id: course.id} }
  let(:anonymous) { Xikolo::Common::Auth::CurrentUser.from_session({}) }
  let(:user_id) { generate(:user_id) }
  let(:user) { Xikolo::Common::Auth::CurrentUser.from_session('user_id' => user_id, 'permissions' => {}, 'features' => {}, 'user' => {'anonymous' => false}, 'masqueraded' => false) }

  describe '#icon_class' do
    subject { presenter.icon_class }

    let(:item_params) { super().merge content_type: 'lti_exercise' }

    context 'as self-test' do
      let(:item_params) { super().merge exercise_type: 'selftest' }

      it { is_expected.to eq 'display-code' }
    end

    context 'as main exercise' do
      let(:item_params) { super().merge exercise_type: 'main' }

      it { is_expected.to eq 'display-code' }
    end

    context 'as bonus exercise' do
      let(:item_params) { super().merge exercise_type: 'bonus' }

      it { is_expected.to eq 'display-code+circle-star' }
    end

    context 'without exercise' do
      let(:item_params) { super().merge exercise_type: nil }

      it { is_expected.to eq 'display-code' }
    end
  end

  describe '#grades?' do
    subject { presenter.grades? }

    context 'without grades' do
      it { is_expected.to be false }
    end

    context 'with grades' do
      before { create(:lti_grade, gradebook:) }

      it { is_expected.to be true }

      context 'as a survey' do
        let(:item_params) { super().merge exercise_type: 'survey' }

        it { is_expected.to be false }
      end
    end
  end
end
