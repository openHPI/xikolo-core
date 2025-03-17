# frozen_string_literal: true

require 'spec_helper'

describe UnsupportedItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new item:, section:, course:, user:
  end

  let(:item_id) { generate(:uuid) }
  let(:user_id) { generate(:user_id) }
  let(:item_params) { {id: item_id} }
  let(:item) { Xikolo::Course::Item.new item_params.merge(content_type: 'unsupported_type') }
  let(:course) { Xikolo::Course::Course.new id: generate(:course_id), course_code: 'test' }
  let(:section) { Xikolo::Course::Section.new id: generate(:section_id), course: course }
  let(:features) { {} }
  let(:masqueraded) { false }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => %w[course.content.access.available],
      'features' => features,
      'masqueraded' => masqueraded,
      'user' => {'anonymous' => false}
    )
  end

  describe '#icon_class' do
    subject { presenter.icon_class }

    context 'as self-test' do
      let(:item_params) { super().merge exercise_type: 'selftest' }

      it { is_expected.to be_empty }
    end

    context 'as main exercise' do
      let(:item_params) { super().merge exercise_type: 'main' }

      it { is_expected.to be_empty }
    end

    context 'as bonus exercise' do
      let(:item_params) { super().merge exercise_type: 'bonus' }

      it { is_expected.to be_empty }
    end

    context 'without exercise' do
      let(:item_params) { super().merge exercise_type: nil }

      it { is_expected.to be_empty }
    end
  end
end
