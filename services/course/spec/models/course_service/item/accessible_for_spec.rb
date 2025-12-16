# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Item, '#accessible_for' do
  subject(:accessible_for) { item.accessible_for(user_id:) }

  let(:item) { create(:'course_service/item') }

  context 'for a legacy course' do
    context 'without a user ID' do
      let(:user_id) { nil }

      it { expect { accessible_for }.to raise_error(ArgumentError) }
    end

    context 'with a user ID' do
      let(:user_id) { generate(:user_id) }

      it { is_expected.to be true }
    end
  end

  context 'for a course with content tree' do
    let(:course) { create(:'course_service/course', :with_content_tree) }
    let(:section) { create(:'course_service/section', course:) }
    let(:regular_item) { create(:'course_service/item', section:) }
    let(:item_branch1) { create(:'course_service/item', section:) }
    let(:item_branch2) { create(:'course_service/item', section:) }
    let(:fork) { create(:'course_service/fork', section:, course:) }

    # Create all the section children to store them in the desired order
    before do
      regular_item
      fork
      item_branch1.node.move_to_child_of(fork.branches[0].node)
      item_branch2.node.move_to_child_of(fork.branches[1].node)

      # Reload course structure record to recalculate tree indices.
      course.node.reload
    end

    context 'without a user ID' do
      let(:user_id) { nil }

      it { expect { accessible_for }.to raise_error(ArgumentError) }
    end

    context 'with a user ID' do
      let(:user_id) { generate(:user_id) }

      context 'the user is not assigned to a content test group' do
        # The user is automatically assigned to a group (branch 1) when requesting the item.
        context 'regular item' do
          let(:item) { regular_item }

          it { is_expected.to be true }
        end

        context 'item in first branch' do
          let(:item) { item_branch1 }

          it { is_expected.to be true }
        end

        context 'item in second branch' do
          let(:item) { item_branch2 }

          it { is_expected.to be false }
        end
      end

      context 'the user is already assigned to a content test group (branch 2)' do
        before do
          CourseService::Duplicated::Membership.create!(user_id:, group_id: fork.branches[1].group_id)
        end

        context 'regular item' do
          let(:item) { regular_item }

          it { is_expected.to be true }
        end

        context 'item in first branch' do
          let(:item) { item_branch1 }

          it { is_expected.to be false }
        end

        context 'item in second branch' do
          let(:item) { item_branch2 }

          it { is_expected.to be true }
        end
      end
    end
  end
end
