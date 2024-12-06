# frozen_string_literal: true

require 'spec_helper'

describe 'Progresses: List', type: :request do
  subject(:list) { api.rel(:progresses).get(params).value! }

  let(:api) { Restify.new(:test).get.value }
  let(:params) { {} }
  let(:user_id) { generate(:user_id) }
  let(:course) { create(:course) }

  context 'without valid course and user provided' do
    it 'responds with 404 Not Found' do
      expect { list }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :not_found
      end
    end
  end

  context 'with empty course' do
    let(:params) do
      super().merge(user_id:, course_id: course.id)
    end

    it 'contains a basic course progress structure' do
      course_progress = list.map(&:to_hash).last
      expect(course_progress).to include(
        'kind' => 'course',
        'resource_id' => course.id,
        'visits' => {'percentage' => 0, 'total' => 0, 'user' => 0}
      )
      expect(course_progress).not_to include('items')
    end
  end

  context 'with course content' do
    let(:params) do
      super().merge(user_id:, course_id: course.id)
    end
    let(:section) { create(:section, course:, title: 'Week 1', start_date: 10.days.ago) }

    before do
      [
        create(:item, :quiz, :with_max_points, section:, published: true, title: 'Quiz 1'),
        create(:item, :quiz, :with_max_points, section:, published: true, title: 'Quiz 2'),
        create(:item, :quiz, :with_max_points, section:, published: true, title: 'Quiz 3'),
        create(:item, :quiz, :with_max_points, section:, published: true, title: 'Quiz 4'),
      ]
    end

    it { expect(list.map(&:to_hash)).to all(include('kind', 'resource_id')) }

    it 'contains a section progress' do
      section_progress = list.map(&:to_hash).first
      expect(section_progress).to include(
        'kind' => 'section',
        'title' => 'Week 1'
      )

      expect(section_progress['items'].count).to eq 4
    end

    context 'with forks (and branches)' do
      let(:course) { create(:course, :with_content_tree) }
      let(:item1) { create(:item, section:, title: 'Item 1') }
      let(:item2) { create(:item, section:, title: 'Item 2') }
      let(:item3) { create(:item, section:, title: 'Item 3') }
      let(:item4) { create(:item, section:, title: 'Item 4') }
      let(:fork) { create(:fork, section:, course:, title: 'Fork') }

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

      context 'the user is not assigned to a content test group' do
        # The user is automatically assigned to a group when requesting the items.
        it 'assigns the user and lists the items in the correct order, including branch items' do
          section_progress = list.map(&:to_hash).first
          expect(section_progress['items'].pluck('title')).to eq ['Quiz 1', 'Quiz 2', 'Quiz 3', 'Quiz 4', 'Item 1', 'Item 2', 'Item 3']
        end
      end

      context 'the user is already assigned to a content test group' do
        before do
          Duplicated::Membership.create!(user_id:, group_id: fork.branches[1].group_id)
        end

        # The user is not re-assigned this time as the user is already member
        # of a group.
        it 'lists the items for the user in the correct order' do
          section_progress = list.map(&:to_hash).first
          expect(section_progress['items'].pluck('title')).to eq ['Quiz 1', 'Quiz 2', 'Quiz 3', 'Quiz 4', 'Item 1', 'Item 4']
        end
      end

      context 'with an unpublished item' do
        before do
          item5 = create(:item, section:, published: false, title: 'Item 5')
          item5.node.move_to_child_of(fork.branches[0].node)

          # Reload section structure record to recalculate tree indices.
          section.node.reload
        end

        # The user is automatically assigned to a group when requesting the items.
        it 'assigns the user and lists the items in the correct order, not including unpublished items' do
          section_progress = list.map(&:to_hash).first
          expect(section_progress['items'].pluck('title')).to eq ['Quiz 1', 'Quiz 2', 'Quiz 3', 'Quiz 4', 'Item 1', 'Item 2', 'Item 3']
        end
      end

      context 'with an unpublished section' do
        before do
          section2 = create(:section, course:, published: false, title: 'Week Unpublished')
          create(:item, section: section2, title: 'Item Section 2')

          # Reload course structure record to recalculate tree indices.
          course.node.reload
        end

        it 'does not include the section progress for the unpublished section' do
          progresses = list.map(&:to_hash)
          expect(progresses).to include(
            hash_including('kind' => 'section', 'title' => 'Week 1')
          )
          expect(progresses).not_to include(
            hash_including('kind' => 'section', 'title' => 'Week Unpublished')
          )
        end
      end
    end
  end
end
