# frozen_string_literal: true

require 'spec_helper'

describe Structure::UserItemsSelector, type: :model do
  subject(:selector) do
    # The root node must be reloaded here, as we have modified the tree
    # structure in the before blocks. This rebuilds the nested set in SQL but
    # does not update the `lft` and `rgt` fields in already loaded models. They
    # must be updated, otherwise queries (e.g. descendants) will not work
    # correctly.
    described_class.new(node.reload, user_id)
  end

  let(:node) { course.node }
  let(:course) { create(:course, :with_content_tree) }
  let(:user_id) { generate(:user_id) }

  context 'with simple course content tree' do
    let(:s1) { create(:section, course:) }
    let(:s2) { create(:section, course:) }

    let!(:item1) { create(:item, section: s1) }
    let!(:item2) { create(:item, section: s1) }
    let!(:item3) { create(:item, section: s2) }
    let!(:item4) { create(:item, section: s2) }

    before do
      # Mini tweak to test sorting
      item2.node.move_to_left_of(item1.node)
    end

    it 'returns items from all sections' do
      expect(selector.items).to eq [item2, item1, item3, item4]
    end

    context 'with section node' do
      let(:node) { s2.node }

      it 'returns items only from section' do
        expect(selector.items).to eq [item3, item4]
      end
    end
  end

  context 'with content test' do
    let(:content_test) { create(:content_test, identifier: 'ct', course:) }

    let(:s1) { create(:section, course:) }
    let(:s2) { create(:section, course:) }
    let(:f1) { create(:fork, section: s1, content_test:) }
    let(:f2) { create(:fork, section: s2, content_test:) }

    # Assign titles to items to ease debugging. They describe where the items
    # should be placed and how they should be ordered.
    let(:item1) { create(:item, section: s1, title: '1.1A') }
    let(:item2) { create(:item, section: s1, title: '1.1B') }
    let(:item3) { create(:item, section: s1, title: '1.2') }
    let(:item4) { create(:item, section: s1, title: '1.3') }
    let(:item5) { create(:item, section: s2, title: '2.1') }
    let(:item6) { create(:item, section: s2, title: '2.2') }
    let(:item7) { create(:item, section: s2, title: '2.3A') }
    let(:item8) { create(:item, section: s2, title: '2.3B') }
    let(:item9) { create(:item, section: s2, title: '2.4') }

    # Create all the section children to store them in the desired order
    before do
      # Section 1
      f1
      item3
      item4

      # Section 1: Items nested in fork 1
      item1.node.move_to_child_of(f1.branches[0].node)
      item2.node.move_to_child_of(f1.branches[1].node)

      # Section 2
      item5
      item6
      f2 # This one lives between two items, to check for correct sorting
      item9

      # Section 2: Items nested in fork 2
      item7.node.move_to_child_of(f2.branches[0].node)
      item8.node.move_to_child_of(f2.branches[1].node)
    end

    it 'assigns the user to a content test group' do
      expect { selector.items }.to change(Duplicated::Membership, :count).from(0).to(1)

      Duplicated::Membership.take.tap do |membership|
        expect(membership.user_id).to eq user_id
        expect(membership.group_id).to eq f1.branches[0].group_id
      end
    end

    it 'returns items from all sections and assigned branches' do
      expect(selector.items.map(&:title)).to eq [item1, item3, item4, item5, item6, item7, item9].map(&:title)
    end

    context 'with existing membership' do
      before do
        Duplicated::Membership.create!(
          group_id: f1.branches[1].group_id,
          user_id:
        )
      end

      it 'does not assign the user to any other group' do
        expect { selector.items }.not_to change(Duplicated::Membership, :count)
      end

      it 'returns items from all sections and assigned branches' do
        expect(selector.items.map(&:title)).to eq [item2, item3, item4, item5, item6, item8, item9].map(&:title)
      end
    end

    context 'with section node' do
      let(:node) { s1.node }

      it 'only returns items from given section and assigned branches within the section' do
        expect(selector.items).to eq [item1, item3, item4]
      end
    end

    context 'with invalid user ID (e.g. anonymous user)' do
      let(:user_id) { 'anonymous' }

      it 'does not assign the user to a content test group' do
        expect { selector.items }.not_to change(Duplicated::Membership, :count).from(0)
      end

      it 'returns items from all sections but no branch items' do
        expect(selector.items).to eq [item3, item4, item5, item6, item9]
      end
    end
  end
end
