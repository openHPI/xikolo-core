# frozen_string_literal: true

require 'spec_helper'

describe VideoItemPresenter, type: :presenter do
  let(:presenter) { described_class.build item, course, user, params: }
  let(:params) { ActionController::Parameters.new(request_params) }
  let(:request_params) do
    {'controller' => 'items', 'action' => 'show', 'course_id' => course.id, 'id' => video.id}
  end
  let(:course) { create(:course) }
  let(:course_resource) { Xikolo::Course::Course.new id: course.id, course_code: course.course_code }
  let(:section) { create(:section, course:) }
  let(:section_resource) { build(:'course:section', id: section.id, course_id: course.id) }
  let(:item) { Xikolo::Course::Item.new item_params }
  let(:item_params) { {id: generate(:item_id), content_id: video.id, section_id: section.id} }
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
end
