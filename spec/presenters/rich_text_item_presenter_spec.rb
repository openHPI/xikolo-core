# frozen_string_literal: true

require 'spec_helper'
describe RichTextItemPresenter, type: :presenter do
  subject { presenter }

  let(:presenter) { described_class.new item:, course:, user: current_user }
  let(:item) { build(:'course:item', **item_params) }
  let(:item_id) { SecureRandom.uuid }
  let(:item_params) { {id: item_id} }
  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:current_user) { CurrentUser::AnonymousUser.new(context_id: 'root') }

  describe '#icon_class' do
    subject { presenter.icon_class }

    let(:item_params) { super().merge content_type: 'rich_text' }

    it { is_expected.to eq 'text' }
  end
end
