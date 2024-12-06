# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Fork, type: :model do
  subject(:fork) { content_test.forks.build(section:, title: 'Course Introduction') }

  let(:content_test) { create(:content_test, course:, identifier: 'gamification', groups: %w[plain game]) }
  let(:course) { create(:course, :with_content_tree, course_code: 'games2021') }
  let(:section) { create(:section, course:) }

  describe 'creation' do
    it 'creates a node in the course content tree' do
      fork.save!

      expect(fork.node).to be_a Structure::Fork
      expect(fork.node.course).to eq course
      expect(fork.node.parent).to eq section.node
    end

    describe 'automatic creation of branches' do
      it 'creates a branch for every group' do
        expect do
          fork.save!
        end.to change { fork.branches.count }.from(0).to(2)
      end

      it 'gives the branches titles based on the fork and the groups' do
        fork.save!

        titles = fork.branches.map(&:title)
        expect(titles).to eq [
          'Course Introduction - plain',
          'Course Introduction - game',
        ]
      end

      it "associates the new branches with the content test's groups" do
        fork.save!

        groups = fork.branches.map(&:group)
        expect(groups).to match [
          have_attributes(name: 'course.games2021.content_test.gamification.plain'),
          have_attributes(name: 'course.games2021.content_test.gamification.game'),
        ]
      end

      it 'creates nodes for the branches in the course content tree' do
        fork.save!

        fork.branches.each do |branch|
          expect(branch.node).to be_a Structure::Branch
          expect(branch.node.course).to eq course
          expect(branch.node.parent).to eq fork.node
        end
      end
    end
  end
end
