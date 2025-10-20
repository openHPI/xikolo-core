# frozen_string_literal: true

require 'spec_helper'

describe 'Items: Position', type: :request do
  variant 'Without course content tree (traditional)' do
    let(:course) { create(:'course_service/course', course_code: 'the-course') }
    let(:variant_before) do
      # *After* other items exist, add a new item in front of them.
      # This lets us test the public "position" attribute.
      late_item.move_to_top
    end
  end

  variant 'With course content tree' do
    let(:course) { create(:'course_service/course', :with_content_tree, course_code: 'the-course') }
    let(:variant_before) do
      # Create a corresponding course content tree:
      fork = create(:'course_service/fork', section:, course:, title: 'Fork')
      items[1].node.move_to_child_of(fork.branches[0].node)

      # NOTE: When requesting items, the user will automatically be assigned
      # to group 1 of the content test. Therefore, we don't need to create a
      # membership here.

      # *After* other items exist, add a new item in front of them.
      # This lets us test the public "position" attribute.
      late_item.node.move_to_left_of items[0].node

      # Reload section structure record to recalculate tree indices.
      section.node.reload
    end
  end

  let(:api) { Restify.new(:test).get.value }
  let(:section) { create(:'course_service/section', course:, title: 'Week 1') }
  let!(:items) { create_list(:'course_service/item', 2, :quiz, :with_max_points, section:) }
  let(:late_item) { create(:'course_service/item', :quiz, section:).tap {|i| items << i } }
  let(:user_id) { generate(:user_id) }

  before do
    # Specifying a native `before` blocks here and in variants leads to a
    # confusing execution order. Also, Rubocop will legitimately complain.
    variant_before
  end

  with_all do
    it 'exposes the same position for lists and for individual items' do
      section_items = api.rel(:items).get({section_id: section.id, user_id:}).value!

      # Ensure the following loop actually has something to assert on
      expect(section_items.count).to eq 3

      section_items.each do |list_item|
        individual_item = api.rel(:item).get({id: list_item['id'], user_id:}).value!

        expect(individual_item['position']).to eq list_item['position']
      end
    end
  end
end
