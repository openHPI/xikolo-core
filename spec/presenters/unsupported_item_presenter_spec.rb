# frozen_string_literal: true

require 'spec_helper'

describe UnsupportedItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new item:, course:, user:
  end

  let(:user_id) { generate(:user_id) }
  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item_params) { {id: generate(:uuid)} }
  let(:item) { build(:'course:item', **item_params, content_type: 'unsupported_type') }
  let(:session) { create(:'account_service/session') }
  let(:user) { CurrentUser::User.new(session:, context_id: 'root') }

  before do
    role = create(:'account_service/role', permissions: %w[course.content.access.available])
    create(:'account_service/grant', principal: session.user, role:)
  end

  describe '#icon_class' do
    subject { presenter.icon_class }

    context 'as self-test' do
      let(:item_params) { super().merge exercise_type: 'selftest' }

      it { is_expected.to eq 'learning_material' }
    end

    context 'as main exercise' do
      let(:item_params) { super().merge exercise_type: 'main' }

      it { is_expected.to eq 'learning_material' }
    end

    context 'as bonus exercise' do
      let(:item_params) { super().merge exercise_type: 'bonus' }

      it { is_expected.to eq 'learning_material' }
    end

    context 'without exercise' do
      let(:item_params) { super().merge exercise_type: nil }

      it { is_expected.to eq 'learning_material' }
    end
  end
end
