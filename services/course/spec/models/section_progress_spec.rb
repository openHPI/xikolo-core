# frozen_string_literal: true

require 'spec_helper'

describe SectionProgress, type: :model do
  subject(:progress) { described_class.create(section:, user_id:) }

  let(:section) { create(:section) }
  let(:user_id) { generate(:user_id) }

  let!(:videos) do
    Array.new(2) {|i| create(:item, title: "Video #{i + 1}", section:) }
  end

  let!(:selftests) do
    Array.new(2) {|i| create(:item, :quiz, title: "Selftest #{i + 1}", section:, max_dpoints: 10) }
  end

  let!(:homework) { create(:item, :homework, title: 'Homework 1', section:, max_dpoints: 50) }
  let!(:bonus) { create(:item, :quiz, :bonus, title: 'Bonus 1', section:, max_dpoints: 20) }

  describe '#calculate!' do
    subject(:calculated) { progress.tap(&:calculate!) }

    context 'without any results for the user' do
      it 'creates an empty progress' do
        expect(calculated).to have_attributes(
          visits: 0,
          main_dpoints: 0,
          main_exercises: 0,
          bonus_dpoints: 0,
          bonus_exercises: 0,
          selftest_dpoints: 0,
          selftest_exercises: 0
        )
      end
    end

    context 'with perfect score for each item' do
      before do
        selftests.each {|selftest| create(:result, user_id:, item: selftest, dpoints: 10) }
        create(:result, user_id:, item: homework, dpoints: 50)
        create(:result, user_id:, item: bonus, dpoints: 20)
      end

      it 'correctly sums up the scores' do
        expect(calculated).to have_attributes(
          visits: 0,
          main_dpoints: 50,
          main_exercises: 1,
          bonus_dpoints: 20,
          bonus_exercises: 1,
          selftest_dpoints: 20,
          selftest_exercises: 2
        )
      end
    end

    context 'with perfect score for an unpublished item' do
      # NOTE: This is not an intended scenario / realistic use case, but
      # important as a regression test since unpublished items must be ignored.
      before do
        selftests.each do |selftest|
          selftest.update!(published: false)
          create(:result, user_id:, item: selftest, dpoints: 10)
        end

        homework.update!(published: false)
        create(:result, user_id:, item: homework, dpoints: 50)

        bonus.update!(published: false)
        create(:result, user_id:, item: bonus, dpoints: 20)
      end

      it 'ignores the unpublished ones' do
        expect(calculated).to have_attributes(
          visits: 0,
          main_dpoints: 0,
          main_exercises: 0,
          bonus_dpoints: 0,
          bonus_exercises: 0,
          selftest_dpoints: 0,
          selftest_exercises: 0
        )
      end
    end

    context 'with perfect score for upcoming items' do
      # TODO: Check whether to remove this scenario.
      # This is not a very realistic scenario as there should be no scores
      # for upcoming items (except for admins testing the quizzes).
      #
      # This scenario has been introduced with XI-4788 and either
      # reverse-engineered based on the `SectionProgress` logic or originated
      # from scenarios in the existing specs, e.g. for the `ProgressController`
      # (see `controllers/progresses_controller_spec.rb#L840-1025`).
      before do
        selftests.each do |selftest|
          selftest.update!(start_date: 10.days.from_now)
          create(:result, user_id:, item: selftest, dpoints: 10)
        end

        homework.update!(start_date: 10.days.from_now)
        create(:result, user_id:, item: homework, dpoints: 50)

        bonus.update!(start_date: 10.days.from_now)
        create(:result, user_id:, item: bonus, dpoints: 30)
      end

      it 'takes the upcoming items into account' do
        expect(calculated).to have_attributes(
          visits: 0,
          main_dpoints: 50,
          main_exercises: 1,
          bonus_dpoints: 30,
          bonus_exercises: 1,
          selftest_dpoints: 20,
          selftest_exercises: 2
        )
      end
    end

    context 'with multiple scores' do
      before do
        create(:result, user_id:, item: homework, dpoints: 50, created_at: 2.days.ago)
        create(:result, user_id:, item: homework, dpoints: 20, created_at: 1.day.ago)
        create(:result, user_id:, item: bonus, dpoints: 20, created_at: 2.days.ago)
        create(:result, user_id:, item: bonus, dpoints: 10, created_at: 1.day.ago)
      end

      context 'for a normal homework' do
        it 'returns the best result for the user' do
          expect(calculated).to have_attributes(
            visits: 0,
            main_dpoints: 50,
            main_exercises: 1,
            bonus_dpoints: 20,
            bonus_exercises: 1,
            selftest_dpoints: 0,
            selftest_exercises: 0
          )
        end

        context 'as a proctored user' do
          before do
            create(:enrollment, course: section.course, user_id:, proctored: true)
          end

          # WATCH OUT: The last result should only be used for items that are
          # themselves proctored.
          it 'still returns the best result for the user' do
            expect(calculated).to have_attributes(
              visits: 0,
              main_dpoints: 50,
              main_exercises: 1,
              bonus_dpoints: 20,
              bonus_exercises: 1,
              selftest_dpoints: 0,
              selftest_exercises: 0
            )
          end
        end
      end

      context 'for a proctored homework' do
        before do
          homework.update!(proctored: true, submission_deadline: 5.days.from_now)
          bonus.update!(proctored: true, submission_deadline: 5.days.from_now)
        end

        it 'returns the best result for the user' do
          expect(calculated).to have_attributes(
            visits: 0,
            main_dpoints: 50,
            main_exercises: 1,
            bonus_dpoints: 20,
            bonus_exercises: 1,
            selftest_dpoints: 0,
            selftest_exercises: 0
          )
        end

        context 'as a proctored user' do
          before do
            create(:enrollment, course: section.course, user_id:, proctored: true)
          end

          it 'returns the latest result for the user' do
            expect(calculated).to have_attributes(
              visits: 0,
              main_dpoints: 20,
              main_exercises: 1,
              bonus_dpoints: 10,
              bonus_exercises: 1,
              selftest_dpoints: 0,
              selftest_exercises: 0
            )
          end
        end
      end
    end

    context 'with visits' do
      before do
        videos.each {|video| create(:visit, user_id:, item: video) }
        selftests.each {|selftest| create(:visit, user_id:, item: selftest) }
        create(:visit, user_id:, item: homework)
        create(:visit, user_id:, item: bonus)
      end

      it 'correctly sums up the visits' do
        expect(calculated).to have_attributes(
          visits: 6,
          main_dpoints: 0,
          main_exercises: 0,
          bonus_dpoints: 0,
          bonus_exercises: 0,
          selftest_dpoints: 0,
          selftest_exercises: 0
        )
      end
    end

    context 'with visits for items in other sections' do
      before do
        create(:visit, user_id:, item: videos.first)
        create(:visit, user_id:)
      end

      it "only counts visits for items in the user's section" do
        expect(calculated).to have_attributes(
          visits: 1,
          main_dpoints: 0,
          main_exercises: 0,
          bonus_dpoints: 0,
          bonus_exercises: 0,
          selftest_dpoints: 0,
          selftest_exercises: 0
        )
      end
    end

    context 'with visits for optional items' do
      # NOTE: Visits for optional items are always ignored.
      before do
        create(:visit, user_id:, item: videos.first)

        optional_item = create(:item, section:, optional: true)
        create(:visit, user_id:, item: optional_item)
      end

      it 'only counts visits for required items' do
        expect(calculated).to have_attributes(
          visits: 1,
          main_dpoints: 0,
          main_exercises: 0,
          bonus_dpoints: 0,
          bonus_exercises: 0,
          selftest_dpoints: 0,
          selftest_exercises: 0
        )
      end
    end

    context 'with visits for items in optional sections' do
      # NOTE: Visits for items in optional section are always ignored.
      before do
        section.update!(optional_section: true)
        create(:visit, user_id:, item: videos.first)
      end

      it 'ignores visits in optional sections' do
        expect(calculated).to have_attributes(
          visits: 0,
          main_dpoints: 0,
          main_exercises: 0,
          bonus_dpoints: 0,
          bonus_exercises: 0,
          selftest_dpoints: 0,
          selftest_exercises: 0
        )
      end
    end

    context 'with visits for unpublished items' do
      before do
        create(:visit, user_id:, item: videos.first)

        unpublished_item = create(:item, section:, published: false)
        create(:visit, user_id:, item: unpublished_item)
      end

      it 'only counts visits for published items' do
        expect(calculated).to have_attributes(
          visits: 1,
          main_dpoints: 0,
          main_exercises: 0,
          bonus_dpoints: 0,
          bonus_exercises: 0,
          selftest_dpoints: 0,
          selftest_exercises: 0
        )
      end
    end

    context 'for an alternative section' do
      let(:section) { create(:section, :child) }

      it 'sets the best alternative' do
        expect { calculated }.to change { progress.reload.alternative_progress_for }.from(nil).to(section.parent.id)
      end
    end

    context 'for a section with a fork' do
      let(:section) { create(:section, course:) }
      let(:course) { create(:course, :with_content_tree) }
      let!(:b1_video) { create(:item, title: 'Video B1', section:) }
      let!(:b1_selftest) { create(:item, :quiz, title: 'Selftest B1', section:, max_dpoints: 10) }
      let!(:b1_homework) { create(:item, :homework, title: 'Homework B1', section:, max_dpoints: 40) }
      let!(:b1_bonus) { create(:item, :quiz, :bonus, title: 'Bonus B1', section:, max_dpoints: 20) }
      let!(:b2_video) { create(:item, title: 'Video B2', section:) }
      let!(:b2_selftest) { create(:item, :quiz, title: 'Selftest B2', section:, max_dpoints: 10) }
      let!(:b2_homework) { create(:item, :homework, title: 'Homework B2', section:, max_dpoints: 50) }
      let!(:b2_bonus) { create(:item, :quiz, :bonus, title: 'Bonus B2', section:, max_dpoints: 30) }
      let!(:another_user_id) { generate(:user_id) }

      before do
        fork = create(:fork, section:, course:)

        [b1_video, b1_selftest, b1_homework, b1_bonus].each do |item|
          item.node.move_to_child_of(fork.branches[0].node)
        end

        [b2_video, b2_selftest, b2_homework, b2_bonus].each do |item|
          item.node.move_to_child_of(fork.branches[1].node)
        end

        # Reload section structure record to recalculate tree indices.
        section.node.reload

        Duplicated::Membership.create!(user_id:, group_id: fork.branches[0].group_id)
        Duplicated::Membership.create!(user_id: another_user_id, group_id: fork.branches[1].group_id)
      end

      context "without results nor visits for items in the user's branch" do
        before do
          # To be included (an item available for all users):
          create(:result, user_id:, item: homework, dpoints: 50)
          create(:visit, user_id:, item: homework)

          # Not to be included since the score / visit belongs to another user:
          create(:result, user_id: another_user_id, item: bonus, dpoints: 20)
          create(:visit, user_id: another_user_id, item: bonus)
        end

        it 'correctly sums up the scores for items available for all users' do
          expect(calculated).to have_attributes(
            visits: 1,
            main_dpoints: 50,
            main_exercises: 1,
            bonus_dpoints: 0,
            bonus_exercises: 0,
            selftest_dpoints: 0,
            selftest_exercises: 0
          )
        end
      end

      context "with perfect score for each item in the user's branch" do
        before do
          # To be included as before:
          create(:result, user_id:, item: homework, dpoints: 50)
          create(:visit, user_id:, item: homework)

          # To be included from the user's branch:
          create(:result, user_id:, item: b1_selftest, dpoints: 10)
          create(:result, user_id:, item: b1_homework, dpoints: 40)
          create(:result, user_id:, item: b1_bonus, dpoints: 20)
          create(:visit, user_id:, item: b1_selftest)
          create(:visit, user_id:, item: b1_homework)
          create(:visit, user_id:, item: b1_bonus)
          create(:visit, user_id:, item: b1_video)

          # Not included from another branch or user:
          # NOTE: Having results for items in other branches is not intended
          # as switching between branches is not allowed (yet).
          create(:result, user_id:, item: b2_homework, dpoints: 50)
          create(:visit, user_id:, item: b2_homework)
          create(:result, user_id: another_user_id, item: b2_homework, dpoints: 50)
          create(:visit, user_id: another_user_id, item: b2_homework)
        end

        it "sums up points and counts visits for the user's branch items only" do
          expect(calculated).to have_attributes(
            visits: 5,
            main_dpoints: 90,
            main_exercises: 2,
            bonus_dpoints: 20,
            bonus_exercises: 1,
            selftest_dpoints: 10,
            selftest_exercises: 1
          )
        end
      end

      context 'with optional items in a branch' do
        let!(:b1_selftest) do
          create(:item, :quiz, section:, max_dpoints: 10, optional: true)
        end

        before do
          # To be included as before:
          create(:result, user_id:, item: homework, dpoints: 50)
          create(:visit, user_id:, item: homework)

          # To be ignored (optional):
          create(:result, user_id:, item: b1_selftest, dpoints: 10)
          create(:visit, user_id:, item: b1_selftest)
        end

        it 'only counts visits for required items' do
          # NOTE: The visit is ignored (visits), but the
          # score for the self-test is considered.
          expect(calculated).to have_attributes(
            visits: 1,
            main_dpoints: 50,
            main_exercises: 1,
            bonus_dpoints: 0,
            bonus_exercises: 0,
            selftest_dpoints: 10,
            selftest_exercises: 1
          )
        end
      end

      context 'with forks in optional sections' do
        before do
          section.update!(optional_section: true)
          create(:result, user_id:, item: b1_homework, dpoints: 10)
          create(:visit, user_id:, item: b1_homework)

          create(:result, user_id:, item: homework, dpoints: 10)
          create(:visit, user_id:, item: homework)
        end

        it 'ignores scores / visits for the fork' do
          # NOTE: The visits are ignored (visits), but the
          # scores for the homeworks are considered.
          expect(calculated).to have_attributes(
            visits: 0,
            main_dpoints: 20,
            main_exercises: 2,
            bonus_dpoints: 0,
            bonus_exercises: 0,
            selftest_dpoints: 0,
            selftest_exercises: 0
          )
        end
      end
    end
  end

  describe '#points_percentage' do
    subject(:points_percentage) { progress.points_percentage }

    it { expect(points_percentage).to eq 0 }

    context 'with perfect score including bonus points' do
      before do
        progress.update!(
          visits: 6,
          main_dpoints: 50,
          main_exercises: 1,
          bonus_dpoints: 20,
          bonus_exercises: 1,
          selftest_dpoints: 20,
          selftest_exercises: 2
        )
      end

      it 'cuts off at 100% even though the total points exceed this value' do
        expect(points_percentage).to eq 100
      end
    end

    context 'with imperfect score' do
      before do
        progress.update!(
          visits: 6,
          main_dpoints: 34,
          main_exercises: 1,
          bonus_dpoints: 0,
          bonus_exercises: 1,
          selftest_dpoints: 20,
          selftest_exercises: 2
        )
      end

      it { expect(points_percentage).to eq 68.0 }
    end
  end

  describe '#visits_percentage' do
    subject(:visits_percentage) { progress.visits_percentage }

    it { expect(visits_percentage).to eq 0 }

    context 'with complete visits including an optional item' do
      before do
        create(:item, section:, optional: true)
        progress.update!(
          visits: 7,
          main_dpoints: 50,
          main_exercises: 1,
          bonus_dpoints: 20,
          bonus_exercises: 1,
          selftest_dpoints: 20,
          selftest_exercises: 2
        )
      end

      it 'cuts off at 100% even though the total visits exceed this value' do
        expect(visits_percentage).to eq 100
      end
    end

    context 'with incomplete visits' do
      before do
        progress.update!(
          visits: 5,
          main_dpoints: 50,
          main_exercises: 1,
          bonus_dpoints: 20,
          bonus_exercises: 1,
          selftest_dpoints: 20,
          selftest_exercises: 2
        )
      end

      it { expect(visits_percentage).to be_within(0.01).of(83.33) }
    end
  end

  describe '#for_alternative?' do
    subject(:for_alternative) { progress.for_alternative? }

    it { expect(for_alternative).to be false }

    context 'for a child section' do
      let(:section) { create(:section, :child) }

      it { expect(for_alternative).to be true }
    end
  end

  describe 'when deleting a section progress' do
    subject(:destroy_progress) { section_progress.destroy }

    let(:section_progress) do
      create(:section_progress, section:, user_id:)
    end

    it 'triggers the update of the corresponding course progress' do
      expect(LearningEvaluation::UpdateCourseProgressWorker).to receive(:perform_async)
        .with(section.course_id, user_id)
        .and_call_original
      expect { destroy_progress }.to change(LearningEvaluation::UpdateCourseProgressWorker.jobs, :size).from(0).to(1)
    end
  end
end
