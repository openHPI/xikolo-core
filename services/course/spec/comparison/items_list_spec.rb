# frozen_string_literal: true

require 'spec_helper'

describe 'Items: List', type: :request do
  subject(:list) { api.rel(:items).get(params).value! }

  variant 'Without course content tree (traditional)' do
    let(:course) { create(:course, course_code: 'the-course') }
    let(:variant_before) do
      # *After* other items exist, add a new item in front of them.
      # This lets us test the public "position" attribute.
      late_item.move_to_top
    end
  end

  variant 'With course content tree' do
    let(:course) { create(:course, :with_content_tree, course_code: 'the-course') }
    let(:params) { super().merge(section_id: section.id) }
    let(:variant_before) do
      # Create a corresponding course content tree:
      fork = create(:fork, section:, course:, title: 'Fork')
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
  let(:params) { {} }
  let(:section) { create(:section, course:, title: 'Week 1') }
  let!(:items) { create_list(:item, 2, :quiz, :with_max_points, section:) }
  let(:late_item) { create(:item, :quiz, section:).tap {|i| items << i } }

  before do
    # Specifying a native `before` blocks here and in variants leads to a
    # confusing execution order. Also, Rubocop will legitimately complain.
    variant_before
  end

  with_all do
    describe 'state_for' do
      let(:user_id) { generate(:user_id) }
      let(:params) { super().merge(state_for: user_id) }

      it { is_expected.to have(3).items }

      # Some API consumers (mobile apps) use the position attribute for sorting
      # on the client side. In non-legacy courses, the "position" attribute in
      # the database has no meaning, but respects order of creation. Therefore,
      # we need to expose a different value here that reflects desired order.
      it 'exposes a monotonically non-decreasing "position" attribute' do
        positions = list.pluck('position')

        expect(positions).to eq positions.sort
      end

      context 'without visit resource' do
        it { expect(list.map(&:to_hash)).to all(include('user_state' => 'new')) }
      end

      context 'with visit resource' do
        before do
          items.each do |item|
            create(:visit, user_id:, item:)
          end
        end

        it { expect(list.map(&:to_hash)).to all(include('user_state' => 'visited')) }

        context 'with result resource' do
          before do
            items.each do |item|
              create(:result, user_id:, item:, dpoints: 3)
            end
          end

          it { expect(list.map(&:to_hash)).to all(include('user_state' => 'graded')) }
        end

        context 'with multiple result resources for the same item' do
          before do
            items.each do |item|
              create(:result, user_id:, item:, dpoints: 3)
              create(:result, user_id:, item:, dpoints: 5)
            end
          end

          it { expect(list.map(&:to_hash)).to all(include('user_state' => 'graded')) }
        end

        context 'with passed submission publishing deadline' do
          before do
            items.each do |item|
              item.update!(submission_publishing_date: 1.day.ago)
              create(:result, user_id:, item:, dpoints: 3)
            end
          end

          it { expect(list.map(&:to_hash)).to all(include('user_state' => 'graded')) }
        end

        context 'with future submission publishing deadline' do
          before do
            items.each do |item|
              item.update!(submission_publishing_date: 1.day.from_now)
              create(:result, user_id:, item:, dpoints: 3)
            end
          end

          it { expect(list.map(&:to_hash)).to all(include('user_state' => 'submitted')) }
        end
      end
    end
  end
end
