# frozen_string_literal: true

require 'spec_helper'

describe CourseService::Item, type: :model do
  let(:user) { create(:'account_service/user') }
  let(:section) { create(:'course_service/section', course:) }
  let!(:first_item) { create(:'course_service/item', section:) }
  let!(:middle_item) { create(:'course_service/item', section:) }
  let!(:last_item) { create(:'course_service/item', section:) }

  shared_examples 'section item navigation' do
    it 'returns the neighboring records' do
      expect(middle_item.previous_item(user_id: user.id)).to eq first_item
      expect(middle_item.next_item(user_id: user.id)).to eq last_item
    end

    it 'does not cross section boundaries' do
      other_section = create(:'course_service/section', course:)
      create(:'course_service/item', section: other_section)

      expect(first_item.previous_item(user_id: user.id)).to be_nil
      expect(last_item.next_item(user_id: user.id)).to be_nil
    end

    it 'has no neighbors for a single-item section' do
      other_section = create(:'course_service/section', course:)
      only_item = create(:'course_service/item', section: other_section)

      expect(only_item.previous_item(user_id: user.id)).to be_nil
      expect(only_item.next_item(user_id: user.id)).to be_nil
    end
  end

  shared_examples 'navigation between sections' do
    let!(:previous_section) { create(:'course_service/section', course:, position: 1) }
    let!(:previous_first) { create(:'course_service/item', section: previous_section) }
    let!(:previous_last) { create(:'course_service/item', section: previous_section) }
    let!(:next_section) { create(:'course_service/section', course:) }
    let!(:next_first) { create(:'course_service/item', section: next_section) }
    let!(:next_last) { create(:'course_service/item', section: next_section) }

    it 'links to the boundary items of adjacent modules' do
      expect(first_item.previous_section_item(user_id: user.id)).to eq previous_last
      expect(last_item.next_section_item(user_id: user.id)).to eq next_first
    end

    it 'keeps navigation within the section when there is a positional neighbor' do
      expect(middle_item.previous_section_item(user_id: user.id)).to be_nil
      expect(middle_item.next_section_item(user_id: user.id)).to be_nil
    end

    it 'has no section link at the course boundaries' do
      expect(previous_first.previous_section_item(user_id: user.id)).to be_nil
      expect(next_last.next_section_item(user_id: user.id)).to be_nil
    end

    it 'skips unpublished items in the adjacent module' do
      previous_last.update!(published: false)
      next_first.update!(published: false)

      expect(first_item.previous_section_item(user_id: user.id)).to eq previous_first
      expect(last_item.next_section_item(user_id: user.id)).to eq next_last
    end

    it 'skips unpublished sections' do
      previous_section.update!(published: false)
      next_section.update!(published: false)

      expect(first_item.previous_section_item(user_id: user.id)).to be_nil
      expect(last_item.next_section_item(user_id: user.id)).to be_nil
    end

    it 'does not skip an empty adjacent module' do
      previous_section.items.update_all(published: false)
      next_section.items.update_all(published: false)

      expect(first_item.previous_section_item(user_id: user.id)).to be_nil
      expect(last_item.next_section_item(user_id: user.id)).to be_nil
    end
  end

  context 'in a legacy course' do
    let(:course) { create(:'course_service/course') }

    it_behaves_like 'section item navigation'
    it_behaves_like 'navigation between sections'

    it 'skips unpublished and future items, as positional navigation does' do
      middle_item.update!(published: false)
      expect(first_item.next_item(user_id: user.id)).to eq last_item

      middle_item.update!(published: true, start_date: 1.day.from_now)
      expect(last_item.previous_item(user_id: user.id)).to eq first_item
    end
  end

  context 'in a course with a content tree' do
    let(:course) { create(:'course_service/course', :with_content_tree) }

    it_behaves_like 'section item navigation'
    it_behaves_like 'navigation between sections'

    it 'uses tree order rather than item positions' do
      last_item.node.move_to_left_of(middle_item.node)
      section.node.reload

      expect(first_item.next_item(user_id: user.id)).to eq last_item
      expect(middle_item.previous_item(user_id: user.id)).to eq last_item
    end

    it 'omits an unpublished neighbor without skipping to the following item' do
      middle_item.update!(published: false)

      expect(first_item.next_item(user_id: user.id)).to be_nil
      expect(last_item.previous_item(user_id: user.id)).to be_nil
    end

    it 'retains a published future neighbor, as the position presenter does' do
      middle_item.update!(start_date: 1.day.from_now)

      expect(first_item.next_item(user_id: user.id)).to eq middle_item
      expect(last_item.previous_item(user_id: user.id)).to eq middle_item
    end

    it 'selects the learner branch at an adjacent module boundary' do
      next_section = create(:'course_service/section', course:)
      fork = create(:'course_service/fork', section: next_section, course:)
      selected_item = create(:'course_service/item', section: next_section)
      other_item = create(:'course_service/item', section: next_section)
      selected_item.node.move_to_child_of(fork.branches[0].node)
      other_item.node.move_to_child_of(fork.branches[1].node)
      next_section.node.reload
      fork.content_test.group_for_user(user.id)

      expect(last_item.next_section_item(user_id: user.id)).to eq selected_item
      expect(selected_item.previous_section_item(user_id: user.id)).to eq last_item
    end

    it 'includes every branch at the next module boundary during preview' do
      next_section = create(:'course_service/section', course:)
      fork = create(:'course_service/fork', section: next_section, course:)
      selected_item = create(:'course_service/item', section: next_section)
      other_item = create(:'course_service/item', section: next_section)
      selected_item.node.move_to_child_of(fork.branches[0].node)
      other_item.node.move_to_child_of(fork.branches[1].node)
      other_item.move_to_top
      next_section.node.reload
      fork.content_test.group_for_user(user.id)

      expect(last_item.next_section_item(user_id: user.id)).to eq selected_item
      expect(last_item.next_section_item(user_id: user.id, preview: true)).to eq other_item
    end

    context 'with content-test branches' do
      let(:fork) { create(:'course_service/fork', section:, course:) }
      let(:branch_item) { create(:'course_service/item', section:) }
      let(:other_branch_item) { create(:'course_service/item', section:) }

      before do
        fork.node.move_to_right_of(first_item.node)
        branch_item.node.move_to_child_of(fork.branches[0].node)
        other_branch_item.node.move_to_child_of(fork.branches[1].node)
        section.node.reload
        fork.content_test.group_for_user(user.id)
      end

      it 'selects the learner branch in both directions' do
        expect(first_item.next_item(user_id: user.id)).to eq branch_item
        expect(middle_item.previous_item(user_id: user.id)).to eq branch_item
        expect(branch_item.previous_item(user_id: user.id)).to eq first_item
        expect(branch_item.next_item(user_id: user.id)).to eq middle_item
      end

      it 'preserves positional neighbor selection for preview requests' do
        expect(first_item.next_item(user_id: user.id, preview: true)).to eq middle_item
        expect(middle_item.previous_item(user_id: user.id, preview: true)).to eq first_item
      end

      it 'includes every branch at the previous module boundary during preview' do
        next_section = create(:'course_service/section', course:)
        next_item = create(:'course_service/item', section: next_section)

        expect(next_item.previous_section_item(user_id: user.id)).to eq last_item
        expect(next_item.previous_section_item(user_id: user.id, preview: true)).to eq other_branch_item
      end

      it 'includes positional preview neighbors outside the selected branch' do
        expect(other_branch_item.previous_item(user_id: user.id, preview: true)).to eq branch_item
        expect(branch_item.next_item(user_id: user.id, preview: true)).to eq other_branch_item
      end
    end
  end
end
