# frozen_string_literal: true

require 'spec_helper'

describe 'Items: Show', type: :request do
  subject(:resource) { api.rel(:item).get(params).value! }

  let(:item) { create(:'course_service/item') }
  let(:api) { Restify.new(course_service.root_url).get.value }
  let(:params) { {id: item.id} }

  it { is_expected.to respond_with :ok }
  it { is_expected.to have_rel(:section) }

  describe '[rel=user_grade]' do
    context 'for non-graded items, such as videos' do
      it { is_expected.not_to have_rel(:user_grade) }
    end

    context 'for graded items, i.e. quizzes' do
      let(:item) { create(:'course_service/item', :homework) }

      it { is_expected.to have_rel(:user_grade) }
    end
  end

  describe '[open_mode]' do
    context 'with an item in open mode' do
      let(:item) { create(:'course_service/item', open_mode: true) }

      it 'respects course visibility (the course is in preparation)' do
        expect(resource['open_mode']).to be false
      end

      describe '(requesting raw mode)' do
        let(:params) { super().merge(raw: 1) }

        it 'always returns the open_mode setting' do
          expect(resource['open_mode']).to be true
        end
      end
    end
  end

  describe '(embedding the user visit)' do
    let(:params) { super().merge(embed: 'user_visit') }

    context 'without the user ID' do
      it { is_expected.to respond_with :ok }
      it { is_expected.not_to have_key 'user_visit' }
    end

    context 'with a valid user ID' do
      let(:user_id) { generate(:user_id) }
      let(:params) { super().merge(user_id:) }

      it { is_expected.to respond_with :ok }
      it { is_expected.to have_key 'user_visit' }
      its(['user_visit']) { is_expected.to be_nil }

      context 'with a visit by the user' do
        before { create(:'course_service/visit', item:, user_id:) }

        its(['user_visit']) { is_expected.to respond_to(:to_hash) }
      end
    end
  end

  context 'with forks (and branches)' do
    let(:course) { create(:'course_service/course', :with_content_tree) }
    let(:section) { create(:'course_service/section', course:, title: 'Week 1') }
    let(:regular_item) { create(:'course_service/item', section:, title: 'Regular Item') }
    let(:item_branch1) { create(:'course_service/item', section:, title: 'Item in Branch 1') }
    let(:item_branch2) { create(:'course_service/item', section:, title: 'Item in Branch 2') }
    let(:fork) { create(:'course_service/fork', section:, course:, title: 'Fork') }

    let(:json) { JSON.parse resource.response.body }

    # Create all the section children to store them in the desired order
    before do
      regular_item
      fork
      item_branch1.node.move_to_child_of(fork.branches[0].node)
      item_branch2.node.move_to_child_of(fork.branches[1].node)

      # Reload section structure record to recalculate tree indices.
      section.node.reload
    end

    context 'without a provided user ID (e.g., as a course admin)' do
      context 'regular item' do
        let(:params) { {id: regular_item.id} }

        it { is_expected.to respond_with :ok }
        it { expect(json).to include('title' => 'Regular Item') }
      end

      context 'item in first branch' do
        let(:params) { {id: item_branch1.id} }

        it { is_expected.to respond_with :ok }
        it { expect(json).to include('title' => 'Item in Branch 1') }
      end

      context 'item in second branch' do
        let(:params) { {id: item_branch2.id} }

        it { is_expected.to respond_with :ok }
        it { expect(json).to include('title' => 'Item in Branch 2') }
      end
    end

    context 'with a provided user ID' do
      let(:user_id) { generate(:user_id) }
      let(:params) { {id: item_id, user_id:} }

      context 'the user is not assigned to a content test group' do
        # The user is automatically assigned to a group (branch 1) when requesting the item.
        context 'regular item' do
          let(:item_id) { regular_item.id }

          it { is_expected.to respond_with :ok }
          it { expect(json).to include('title' => 'Regular Item') }
        end

        context 'item in first branch' do
          let(:item_id) { item_branch1.id }

          it { is_expected.to respond_with :ok }
          it { expect(json).to include('title' => 'Item in Branch 1') }
        end

        context 'item in second branch' do
          let(:item_id) { item_branch2.id }

          it 'responds with 404 Not Found' do
            expect { resource }.to raise_error(Restify::NotFound)
          end
        end
      end

      context 'the user is already assigned to a content test group (branch 2)' do
        before do
          CourseService::Duplicated::Membership.create!(user_id:, group_id: fork.branches[1].group_id)
        end

        context 'regular item' do
          let(:item_id) { regular_item.id }

          it { is_expected.to respond_with :ok }
          it { expect(json).to include('title' => 'Regular Item') }
        end

        context 'item in first branch' do
          let(:item_id) { item_branch1.id }

          it 'responds with 404 Not Found' do
            expect { resource }.to raise_error(Restify::NotFound)
          end
        end

        context 'item in second branch' do
          let(:item_id) { item_branch2.id }

          it { is_expected.to respond_with :ok }
          it { expect(json).to include('title' => 'Item in Branch 2') }
        end
      end
    end

    describe '(previous / next items)' do
      let(:user_id) { generate(:user_id) }
      let(:regular_item2) { create(:'course_service/item', section:, title: 'Regular Item 2') }
      let(:regular_item3) { create(:'course_service/item', section:, title: 'Regular Item 3') }
      let(:item_branch21) { create(:'course_service/item', section:, title: 'Item in Branch 2-1') }
      let(:item_branch22) { create(:'course_service/item', section:, title: 'Item in Branch 2-2') }
      let(:fork2) { create(:'course_service/fork', section:, course:, content_test: fork.content_test, title: 'Fork 2') }

      before do
        regular_item2
        regular_item3
        fork2
        item_branch21.node.move_to_child_of(fork2.branches[0].node)
        item_branch22.node.move_to_child_of(fork2.branches[1].node)

        # Move around items so we do not rely on creation date for the order.
        regular_item3.node.move_to_right_of(regular_item.node)

        # Reload section structure record to recalculate tree indices.
        section.node.reload

        # Order with legacy implementation, relying on the item position attribute:
        expect(CourseService::Item.course_order).to eq \
          [regular_item, item_branch1, item_branch2, regular_item2, regular_item3, item_branch21, item_branch22]

        # Order with course content tree structure:
        items = CourseService::Structure::UserItemsSelector.new(section.node, user_id).items
        expect(items).to eq [regular_item, regular_item3, item_branch1, regular_item2, item_branch21]
      end

      context 'first regular item' do
        let(:params) { {id: regular_item.id, user_id:} }

        it 'has correct prev/next IDs' do
          expect(json).to include(
            'title' => 'Regular Item',
            'prev_item_id' => nil,
            'next_item_id' => regular_item3.id
          )
        end
      end

      context 'item in first branch' do
        let(:params) { {id: item_branch1.id, user_id:} }

        it 'has correct prev/next IDs' do
          expect(json).to include(
            'title' => 'Item in Branch 1',
            'prev_item_id' => regular_item3.id,
            'next_item_id' => regular_item2.id
          )
        end
      end

      context 'second regular item' do
        let(:params) { {id: regular_item2.id, user_id:} }

        it 'has correct prev/next IDs' do
          expect(json).to include(
            'title' => 'Regular Item 2',
            'prev_item_id' => item_branch1.id,
            'next_item_id' => item_branch21.id
          )
        end
      end

      context 'third regular item' do
        let(:params) { {id: regular_item3.id, user_id:} }

        it 'has correct prev/next IDs' do
          expect(json).to include(
            'title' => 'Regular Item 3',
            'prev_item_id' => regular_item.id,
            'next_item_id' => item_branch1.id
          )
        end
      end

      context 'item in second branch' do
        let(:params) { {id: item_branch21.id, user_id:} }

        it 'has correct prev/next IDs' do
          expect(json).to include(
            'title' => 'Item in Branch 2-1',
            'prev_item_id' => regular_item2.id,
            'next_item_id' => nil
          )
        end
      end
    end
  end
end
