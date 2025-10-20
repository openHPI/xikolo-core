# frozen_string_literal: true

require 'spec_helper'

describe 'Items: List', type: :request do
  subject(:list) { api.rel(:items).get(params).value! }

  let(:api) { Restify.new(:test).get.value }
  let(:params) { {} }
  let(:course) { create(:'course_service/course') }
  let(:section) { create(:'course_service/section', course:, title: 'Week 1') }
  let!(:items) do
    [
      create(:'course_service/item', :quiz, :with_max_points, section:, title: 'Quiz 1'),
      create(:'course_service/item', :quiz, :with_max_points, section:, title: 'Quiz 2'),
      create(:'course_service/item', :quiz, :with_max_points, section:, title: 'Quiz 3'),
      create(:'course_service/item', :quiz, :with_max_points, section:, title: 'Quiz 4'),
    ]
  end

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(4).items }
  it { is_expected.to all have_rel(:section) }

  shared_examples 'an item list with forks and branches' do
    let(:course) { create(:'course_service/course', :with_content_tree) }
    let(:item1) { create(:'course_service/item', section:, title: 'Item 1') }
    let(:item2) { create(:'course_service/item', section:, title: 'Item 2') }
    let(:item3) { create(:'course_service/item', section:, title: 'Item 3') }
    let(:item4) { create(:'course_service/item', section:, title: 'Item 4') }
    let(:fork) { create(:'course_service/fork', section:, course:, title: 'Fork') }

    # Create all the section children to store them in the desired order
    before do
      item1
      fork
      item2.node.move_to_child_of(fork.branches[0].node)
      item3.node.move_to_child_of(fork.branches[0].node)
      item4.node.move_to_child_of(fork.branches[1].node)

      # Reload section structure record to recalculate tree indices.
      section.node.reload
    end

    shared_examples 'a branched item list' do
      context 'the user is not assigned to a content test group' do
        # The user is automatically assigned to a group when requesting the items.
        it 'assigns the user and lists the items in the correct order, including branch items' do
          expect(list.pluck('title')).to eq ['Quiz 1', 'Quiz 2', 'Quiz 3', 'Quiz 4', 'Item 1', 'Item 2', 'Item 3']

          # Inject additional test assertions for this context by specifying a `let` that is passed in a block:
          #
          # it_behaves_like 'an item list with forks and branches' do
          #   let(:branch1_assertions) do
          #     expect(list.map(&:to_hash)).to all(include('user_state' => 'new'))
          #   end
          # end
          branch1_assertions if respond_to? :branch1_assertions
        end
      end

      context 'the user is already assigned to a content test group' do
        before do
          Duplicated::Membership.create!(user_id:, group_id: fork.branches[1].group_id)
        end

        # The user is not re-assigned this time as the user is already member
        # of a group.
        it 'lists the items for the user in the correct order' do
          expect(list.pluck('title')).to eq ['Quiz 1', 'Quiz 2', 'Quiz 3', 'Quiz 4', 'Item 1', 'Item 4']

          # Inject additional test assertions for this context by specifying a `let` that is passed in a block:
          #
          # it_behaves_like 'an item list with forks and branches' do
          #   let(:branch2_assertions) do
          #     expect(list.map(&:to_hash)).to all(include('user_state' => 'new'))
          #   end
          # end
          branch2_assertions if respond_to? :branch2_assertions
        end
      end
    end

    context 'for a section' do
      let(:params) { super().merge(section_id: section.id) }

      it_behaves_like 'a branched item list'
    end

    context 'for a course' do
      let(:params) { super().merge(course_id: course.id) }

      it_behaves_like 'a branched item list'
    end
  end

  describe '(embedding the user visits)' do
    let(:params) { super().merge(embed: 'user_visit') }

    context 'without the user ID' do
      it { is_expected.to respond_with :ok }
      it { is_expected.to have(4).items }

      it 'all rows should not include the "user_visit" key' do
        expect(list.none? {|row| row.key? 'user_visit' }).to be true
      end
    end

    context 'with a valid user ID' do
      let(:user_id) { generate(:user_id) }
      let(:params) { super().merge(user_id:) }

      it { is_expected.to respond_with :ok }
      it { is_expected.to have(4).items }
      it { is_expected.to all(have_key('user_visit')) }
      it { expect(list.map(&:to_hash)).to all(include('user_visit' => nil)) }

      context 'with visits by the user' do
        before do
          create(:'course_service/visit', item: items.first, user_id:)
          create(:'course_service/visit', item: items.second, user_id:)
        end

        it { is_expected.to respond_with :ok }
        it { is_expected.to have(4).items }
        it { expect(list.map(&:to_hash)).to all(have_key('user_visit')) }

        it 'has two items with "user_visit" set to nil' do
          expect(list.select {|row| row['user_visit'].nil? }).to have(2).items
          expect(list.map(&:to_hash).select {|row| row['user_visit'].nil? }).to match([
            a_hash_including('id' => items.third.id),
            a_hash_including('id' => items.fourth.id),
          ])
        end

        it 'has two items with "user_visit" objects that represent the visits' do
          expect(list.select {|row| row['user_visit'].respond_to? :to_hash }).to have(2).items
          expect(list.map(&:to_hash).select {|row| row['user_visit'].respond_to? :to_hash }).to match([
            a_hash_including('id' => items.first.id),
            a_hash_including('id' => items.second.id),
          ])
        end
      end

      context 'with visits by another user' do # regression test
        let(:other_user_id) { generate(:user_id) }

        before do
          create(:'course_service/visit', item: items.first, user_id: other_user_id)
          create(:'course_service/visit', item: items.second, user_id: other_user_id)
        end

        it { is_expected.to respond_with :ok }
        it { is_expected.to have(4).items }
        it { is_expected.to all(have_key('user_visit')) }
        it { expect(list.map(&:to_hash)).to all(include('user_visit' => nil)) }
      end

      it_behaves_like 'an item list with forks and branches' do
        let(:other_user_id) { generate(:user_id) }

        let(:branch1_assertions) do
          # has five items with "user_visit" set to nil
          expect(list.select {|row| row['user_visit'].nil? }).to have(5).items
          expect(list.map(&:to_hash).select {|row| row['user_visit'].nil? }).to match([
            a_hash_including('id' => items.third.id),
            a_hash_including('id' => items.fourth.id),
            a_hash_including('id' => item1.id),
            a_hash_including('id' => item2.id),
            a_hash_including('id' => item3.id),
          ])

          # has two items with "user_visit" objects that represent the visits
          expect(list.select {|row| row['user_visit'].respond_to? :to_hash }).to have(2).items
          expect(list.map(&:to_hash).select {|row| row['user_visit'].respond_to? :to_hash }).to match([
            a_hash_including('id' => items.first.id),
            a_hash_including('id' => items.second.id),
          ])
        end

        let(:branch2_assertions) do
          # has four items with "user_visit" set to nil
          expect(list.select {|row| row['user_visit'].nil? }).to have(4).items
          expect(list.map(&:to_hash).select {|row| row['user_visit'].nil? }).to match([
            a_hash_including('id' => items.third.id),
            a_hash_including('id' => items.fourth.id),
            a_hash_including('id' => item1.id),
            a_hash_including('id' => item4.id),
          ])

          # has two items with "user_visit" objects that represent the visits
          expect(list.select {|row| row['user_visit'].respond_to? :to_hash }).to have(2).items
          expect(list.map(&:to_hash).select {|row| row['user_visit'].respond_to? :to_hash }).to match([
            a_hash_including('id' => items.first.id),
            a_hash_including('id' => items.second.id),
          ])
        end

        before do
          create(:'course_service/visit', item: items.first, user_id:)
          create(:'course_service/visit', item: items.second, user_id:)
          create(:'course_service/visit', item: items.first, user_id: other_user_id)
          create(:'course_service/visit', item: items.second, user_id: other_user_id)
        end

        it { is_expected.to respond_with :ok }
        it { is_expected.to have(8).items }
        it { expect(list.map(&:to_hash)).to all(have_key('user_visit')) }
      end
    end
  end

  describe 'state_for' do
    let(:params) { super().merge(state_for: user_id) }
    let(:user_id) { generate(:user_id) }

    it { is_expected.to have(4).items }
    it { expect(list.map(&:to_hash)).to all(include('user_state' => 'new')) }

    context 'with visited and submitted / graded items' do
      before do
        Visit.create!(user_id:, item: items.first)
        Result.create!(user_id:, item: items.second, dpoints: 10)

        items.third.update!(submission_publishing_date: 2.days.from_now)
        Result.create!(user_id:, item: items.third, dpoints: 10)
      end

      it { expect(list.pluck('user_state')).to eq %w[visited graded submitted new] }
    end

    it_behaves_like 'an item list with forks and branches' do
      let(:branch1_assertions) do
        expect(list.map(&:to_hash)).to all(include('user_state' => 'new'))
      end
      let(:branch2_assertions) do
        expect(list.map(&:to_hash)).to all(include('user_state' => 'new'))
      end
    end
  end

  describe 'user_id' do
    let(:params) { super().merge(user_id:) }
    let(:user_id) { generate(:user_id) }

    it { is_expected.to have(4).items }

    it_behaves_like 'an item list with forks and branches'
  end

  context 'without items with prerequisites' do
    let(:params) { super().merge required_items: 'none' }
    let!(:item_with_requirements) { create(:'course_service/item', required_item_ids: [Item.first.id]) }

    it { is_expected.to have(4).items }

    it 'does not contain the item that has requirements' do
      expect(list.pluck('id')).not_to include(item_with_requirements.id)
    end
  end
end
