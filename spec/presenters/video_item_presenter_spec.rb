# frozen_string_literal: true

require 'spec_helper'

describe VideoItemPresenter, type: :presenter do
  let(:presenter) { described_class.build item, course, user, params: }
  let(:params) { ActionController::Parameters.new(request_params) }
  let(:request_params) do
    {'controller' => 'items', 'action' => 'show', 'course_id' => course.id, 'id' => video.id}
  end
  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item) { build(:'course:item', **item_params) }
  let(:item_params) { {id: generate(:item_id), content_id: video.id, section_id: section.id} }
  let(:session) { create(:'account_service/session') }
  let(:user) { CurrentUser::User.new(session:, context_id: 'root') }
  let(:video) { create(:video) }

  before do
    params.permit(:nvp, :old)
    role = create(:'account_service/role', permissions: ['course.content.access.available'])
    create(:'account_service/grant', principal: session.user, role:)
  end

  describe '#icon_class' do
    subject { presenter.icon_class }

    let(:item_params) { super().merge content_type: 'video' }

    context 'with nothing else set' do
      it { is_expected.to eq 'video' }
    end
  end

  describe '#forum_locked?' do
    subject { presenter.forum_locked? }

    it { is_expected.to be false }

    context 'when the course forum is locked' do
      let(:course) { create(:course, forum_is_locked: true) }

      it { is_expected.to be true }
    end

    context 'when the section forum is locked' do
      before { section.update!(pinboard_closed: true) }

      it { is_expected.to be true }
    end
  end
end
