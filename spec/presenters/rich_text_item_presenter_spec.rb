# frozen_string_literal: true

require 'spec_helper'
describe RichTextItemPresenter, type: :presenter do
  subject { presenter }

  let(:presenter) { described_class.new item:, course:, section:, user: current_user }
  let(:item) { build(:'course:item', **item_params) }
  let(:item_id) { SecureRandom.uuid }
  let(:item_params) { {id: item_id} }
  let(:course) { Xikolo::Course::Course.new course_params }
  let(:course_params) { {id: SecureRandom.uuid, course_code: 'test'} }
  let(:section) { Xikolo::Course::Section.new section_params }
  let(:section_params) { {id: SecureRandom.uuid, course_id: course.id} }
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
