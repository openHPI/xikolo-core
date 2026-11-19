# frozen_string_literal: true

require 'spec_helper'

class SimpleItemContextController
  include ItemContextHelper

  attr_accessor :current_user, :request, :item_presenter
  attr_reader :item

  def initialize(item:)
    @item = item
  end
end

describe ItemContextHelper, type: :helper do
  let(:instance) { SimpleItemContextController.new(item: {'id' => item_record.id}) }
  let(:course) { create(:'course_service/course', skip_account_groups: true) }
  let(:section) { create(:'course_service/section', course:) }
  let(:item_record) { create(:'course_service/item', section:) }
  let(:user) { create(:'account_service/user') }
  let(:current_user) { instance_double(CurrentUser::User, masqueraded?: false, authenticated?: true, id: user.id) }
  let(:headers) { {} }

  before do
    instance.current_user = current_user
    instance.request = instance_double(ActionDispatch::Request, headers:)
    instance.item_presenter = instance_double(ItemPresenter, required_items: [])
  end

  describe '#create_visit!' do
    subject(:create_visit!) { instance.send(:create_visit!) }

    it 'creates a visit for a regular navigation request' do
      expect { create_visit! }.to change(CourseService::Visit, :count).by(1)
    end

    context 'when the request carries the Turbo prefetch header' do
      let(:headers) { {'X-Sec-Purpose' => 'prefetch'} }

      it 'does not create a visit' do
        expect { create_visit! }.not_to change(CourseService::Visit, :count)
      end
    end

    context 'when the user is masquerading' do
      let(:current_user) { instance_double(CurrentUser::User, masqueraded?: true, authenticated?: true) }

      it 'does not create a visit' do
        expect { create_visit! }.not_to change(CourseService::Visit, :count)
      end
    end

    context 'when the user is not authenticated' do
      let(:current_user) { instance_double(CurrentUser::User, masqueraded?: false, authenticated?: false) }

      it 'does not create a visit' do
        expect { create_visit! }.not_to change(CourseService::Visit, :count)
      end
    end

    context 'when the item has unmet requirements' do
      before do
        instance.item_presenter = instance_double(ItemPresenter, required_items: [double])
      end

      it 'does not create a visit' do
        expect { create_visit! }.not_to change(CourseService::Visit, :count)
      end
    end
  end
end
