# frozen_string_literal: true

require 'spec_helper'

describe Course::BottomNavigation, type: :component do
  subject(:component) { described_class.new(course_id: course.id, prev_item_id:, next_item_id:) }

  let(:course) { create(:course) }
  let(:section) { create(:section, course_id: course.id) }

  context 'when a section has multiple items' do
    let(:item_1) { create(:item, title: 'Item 1', section_id: section.id) }
    let(:item_2) { create(:item, title: 'Item 2', section_id: section.id) }
    let(:item_3) { create(:item, title: 'Item 3', section_id: section.id) }

    before do
      item_1
      item_2
      item_3
    end

    context 'with a next item only' do
      let(:prev_item_id) { nil }
      let(:next_item_id) { item_2.id }

      it 'links to the next item only' do
        render_inline(component)
        expect(page).to have_text 'Item 2'
        expect(page).to have_text 'Next'
        expect(page).to have_no_text 'Previous'
      end
    end

    context 'with previous & next items' do
      let(:prev_item_id) { item_1.id }
      let(:next_item_id) { item_3.id }

      it 'links to both the previous & the next item' do
        render_inline(component)
        expect(page).to have_text 'Item 1'
        expect(page).to have_text 'Item 3'
        expect(page).to have_text 'Next'
        expect(page).to have_text 'Previous'
      end
    end

    context 'with a previous item only' do
      let(:prev_item_id) { item_2.id }
      let(:next_item_id) { nil }

      it 'links to the previous item only' do
        render_inline(component)
        expect(page).to have_text 'Item 2'
        expect(page).to have_no_text 'Next'
        expect(page).to have_text 'Previous'
      end
    end
  end

  context 'when a section has multiple items with varying item content types' do
    let(:item_1) { create(:item, section_id: section.id, content_type: 'quiz', exercise_type: 'bonus') } # 'lightbulb-on+circle-star'
    let(:item_2) { create(:item, section_id: section.id, content_type: 'video') } # 'video'
    let(:item_3) { create(:item, section_id: section.id, content_type: 'rich_text') } # 'file-lines'

    before do
      item_1
      item_2
      item_3
    end

    context 'with item 2 as the current item' do
      let(:prev_item_id) { item_1.id }
      let(:next_item_id) { item_3.id }

      it 'renders the correct icon for the previous item (item 1)' do
        render_inline(component)
        expect(page).to have_css '.fa-lightbulb-on'
        expect(page).to have_css '.fa-circle-star'
      end

      it 'renders the correct icon for the next item (item 3)' do
        render_inline(component)
        expect(page).to have_css '.fa-file-lines'
      end
    end

    context 'with item 3 as the current item' do
      let(:prev_item_id) { item_2.id }
      let(:next_item_id) { nil }

      it 'renders the correct icon for the previous item (item 2)' do
        render_inline(component)
        expect(page).to have_css '.fa-video'
      end
    end
  end

  context 'when a section has only one item' do
    let(:item_1) { create(:item, title: 'Item 1', section_id: section.id) }
    let(:prev_item_id) { nil }
    let(:next_item_id) { nil }

    before do
      item_1
    end

    it 'does not display any navigation' do
      render_inline(component)
      expect(page).to have_no_text 'Previous'
      expect(page).to have_no_text 'Next'
    end
  end
end
