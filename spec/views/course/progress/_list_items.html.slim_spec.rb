# frozen_string_literal: true

require 'spec_helper'

describe 'course/progress/_list_items.html.slim', type: :view do
  subject(:html) { render_view; rendered }

  let(:render_view) { render 'course/progress/list_items', items: }
  let(:items) { [presenter] }
  let(:presenter) { ItemPresenter.new item:, course:, user: }
  let(:item) { Xikolo::Course::Item.new item_params }
  let(:item_id) { SecureRandom.uuid }
  let(:item_params) { {id: item_id, content_type: 'test', title: 'The item'} }
  let(:course) { Xikolo::Course::Course.new id: SecureRandom.uuid, course_code: 'test' }
  let(:permissions) { ['course.content.access.available'] }
  let(:user) do
    Xikolo::Common::Auth::CurrentUser.from_session(
      'permissions' => permissions,
      'features' => {},
      'user' => {'anonymous' => false},
      'masqueraded' => false
    )
  end

  context 'without any item' do
    let(:items) { [] }

    it { is_expected.to eq '' }
  end

  context 'with unlocked item' do
    it 'links to the item' do
      expect(html).to include 'href="/courses/test/items/'
    end
  end

  context 'with locked item' do
    let(:item_params) { super().merge(effective_start_date: 2.days.from_now) }

    it 'does not link to the item' do
      expect(html).not_to include 'href="/courses/test/items/'
    end

    it 'marks the item as locked' do
      expect(html).to include '(locked)'
    end
  end

  context 'title' do
    let(:item_params) { super().merge title: 'This is a test.' }

    it { is_expected.to include 'This is a test.' }
  end

  context 'icon_class' do
    it { is_expected.to include 'class="xi-icon fa-regular fa-' }
  end

  context 'visited' do
    context 'with a visited item' do
      let(:item_params) { super().merge user_state: 'visited' }

      it { is_expected.to match 'class=".*progress_item_visited.*"' }
    end

    context 'with an unvisited item' do
      let(:item_params) { super().merge user_state: 'new' }

      it { is_expected.not_to include 'progress_item_visited' }
    end
  end

  context 'url' do
    it { is_expected.to include 'href="/courses/test/items/' }
  end
end
