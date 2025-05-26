# frozen_string_literal: true

require 'spec_helper'
describe RichTextItemPresenter, type: :presenter do
  subject { presenter }

  let(:presenter) { described_class.new item:, course:, user: current_user }
  let(:item) { Xikolo::Course::Item.new item_params }
  let(:item_id) { SecureRandom.uuid }
  let(:item_params) { {id: item_id} }
  let(:course) { create(:course) }
  let(:course_resource) { Xikolo::Course::Course.new id: course.id, course_code: course.course_code }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:anonymous) { Xikolo::Common::Auth::CurrentUser.from_session({}) }
  let(:user) { Xikolo::Common::Auth::CurrentUser.from_session('permissions' => {}, 'features' => {}, 'user' => {'anonymous' => false}, 'masqueraded' => false) }
  let(:current_user) { user }

  describe '#icon_class' do
    subject { presenter.icon_class }

    let(:item_params) { super().merge content_type: 'rich_text' }

    context 'without icon type set' do
      it { is_expected.to eq 'file-lines' }
    end

    context 'with icon type set' do
      let(:item_params) { super().merge icon_type: 'youtube' }

      it { is_expected.to eq 'video+circle-arrow-up-right' }
    end
  end
end
