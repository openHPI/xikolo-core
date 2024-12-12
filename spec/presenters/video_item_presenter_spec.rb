# frozen_string_literal: true

require 'spec_helper'

describe VideoItemPresenter, type: :presenter do
  let(:presenter) { described_class.build item, section, course, user, params: }
  let(:params) { ActionController::Parameters.new(request_params) }
  let(:request_params) do
    {'controller' => 'items', 'action' => 'show', 'course_id' => course.id, 'id' => video.id}
  end
  let(:item) { Xikolo::Course::Item.new item_params }
  let(:item_params) { {id: generate(:item_id), content_id: video.id} }
  let(:course) { Xikolo::Course::Course.new course_params }
  let(:course_params) { {id: generate(:course_id), course_code: 'test'} }
  let(:section) { Xikolo::Course::Section.new section_params }
  let(:section_params) { {id: generate(:section_id), course_id: course.id} }
  let(:features) { {} }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => ['course.content.access.available'],
      'features' => features,
      'user' => {'anonymous' => false},
      'masqueraded' => false
    )
  end
  let(:video) { create(:video) }

  before do
    params.permit(:nvp, :old)
  end

  describe '#icon_class' do
    subject { presenter.icon_class }

    let(:item_params) { super().merge content_type: 'video' }

    context 'with nothing else set' do
      it { is_expected.to eq 'video' }
    end
  end

  describe 'forum_locked?' do
    subject { presenter.forum_locked? }

    context 'by default' do
      it { is_expected.to be_falsy }
    end

    context 'with unlocked course and section forum' do
      let(:section_params) { super().merge pinboard_closed: false }
      let(:course_params) { super().merge forum_is_locked: false }

      it { is_expected.to be_falsy }
    end

    context 'with locked section forum' do
      let(:section_params) { super().merge pinboard_closed: true }
      let(:course_params) { super().merge forum_is_locked: false }

      it { is_expected.to be_truthy }
    end

    context 'with locked course forum' do
      let(:section_params) { super().merge pinboard_closed: false }
      let(:course_params) { super().merge forum_is_locked: true }

      it { is_expected.to be_truthy }
    end

    context 'with locked course and section forum' do
      let(:section_params) { super().merge pinboard_closed: true }
      let(:course_params) { super().merge forum_is_locked: true }

      it { is_expected.to be_truthy }
    end
  end
end
