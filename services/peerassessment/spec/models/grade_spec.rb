# frozen_string_literal: true

# rubocop:disable RSpec/AnyInstance
require 'spec_helper'

describe Grade, type: :model do
  # STUB for course item

  let(:assessment_id) { SecureRandom.uuid }
  let(:assessment)    { create(:peer_assessment, :with_steps, :with_one_rubric, id: assessment_id) }
  let(:user_id)       { SecureRandom.uuid }
  let(:shared_submission) { create(:shared_submission, :as_submitted, peer_assessment: assessment) }
  let!(:submission) { create(:submission, user_id:, shared_submission_id: shared_submission.id) }
  let(:grade) { submission.grade }

  describe 'compute_grade' do
    subject(:compute_grade) { grade.compute_grade }

    before do
      create(:participant, user_id:, peer_assessment_id: assessment_id)

      allow_any_instance_of(Step).to receive(:reschedule_deadline_workers).and_return(true)
      allow_any_instance_of(Step).to receive(:update_item_submission_publish_date).and_return(true)
      allow_any_instance_of(Participant).to receive(:can_receive_grade?).and_return(true)
      allow_any_instance_of(Grade).to receive(:update_course_result).and_return(true)

      assessment.self_assessment_step.update deadline: 1.hour.ago

      2.times do |i|
        create(:review, :as_submitted,
          submission_id: submission.id,
          step_id: assessment.grading_step.id,
          user_id: SecureRandom.uuid,
          optionIDs: [assessment.rubrics.first.rubric_options[i].id])
      end
    end

    it 'calls median_grade with 2 reviews' do
      expect_any_instance_of(Grade).to receive(:median_grade)
        .with(have(2).items)
        .and_call_original
      compute_grade
    end

    context 'with reviews on team submissions' do
      let(:team_submission) { create(:submission, shared_submission_id: shared_submission.id) }

      before do
        create(:review, :as_submitted,
          submission_id: team_submission.id,
          step_id: assessment.grading_step.id,
          user_id: SecureRandom.uuid,
          optionIDs: [assessment.rubrics.first.rubric_options.first.id])
      end

      it 'calls median_grade with 3 reviews' do
        expect_any_instance_of(Grade).to receive(:median_grade)
          .with(have(3).items)
          .and_call_original
        compute_grade
      end
    end
  end

  describe '.average_grade' do
    before do
      3.times do |i|
        create(:review, :as_submitted,
          submission_id: submission.id,
          step_id: assessment.grading_step.id,
          user_id: SecureRandom.uuid,
          optionIDs: [assessment.rubrics.first.rubric_options[i].id])
      end
    end

    it 'computes correctly' do
      # 1 + 2 + 3 / 3
      expect(grade.average_grade(submission.reviews)).to eq 2.0
    end
  end

  describe '.median_grade' do
    context 'with only one review' do
      before do
        create(:review, :as_submitted,
          submission_id: submission.id,
          step_id: assessment.grading_step.id,
          user_id: SecureRandom.uuid,
          optionIDs: [assessment.rubrics.first.rubric_options[0].id])
      end

      it 'equals the average' do
        expect(grade.median_grade(submission.reviews)).to eq grade.average_grade(submission.reviews)
      end
    end

    context 'with only two reviews' do
      before do
        2.times do |i|
          create(:review, :as_submitted,
            submission_id: submission.id,
            step_id: assessment.grading_step.id,
            user_id: SecureRandom.uuid,
            optionIDs: [assessment.rubrics.first.rubric_options[i].id])
        end
      end

      it 'equals the average' do
        expect(grade.median_grade(submission.reviews)).to eq grade.average_grade(submission.reviews)
      end
    end

    context 'with an even amount of reviews (> 2)' do
      before do
        4.times do |i|
          create(:review, :as_submitted,
            submission_id: submission.id,
            step_id: assessment.grading_step.id,
            user_id: SecureRandom.uuid,
            optionIDs: [assessment.rubrics.first.rubric_options[i % 3].id])
        end
      end

      it 'computes correctly' do
        # Reviews points are 1, 1, 2, 3 for the one rubric -> 1 + 2 / 2 = 1.5
        expect(grade.median_grade(submission.reviews)).to eq 1.5
      end
    end

    context 'with an odd amount of reviews (> 2)' do
      before do
        5.times do |i|
          create(:review, :as_submitted,
            submission_id: submission.id,
            step_id: assessment.grading_step.id,
            user_id: SecureRandom.uuid,
            optionIDs: [assessment.rubrics.first.rubric_options[i % 3].id])
        end
      end

      it 'computes correctly' do
        # Reviews points are 1, 1, 2, 2, 3 for the one rubric -> 2
        expect(grade.median_grade(submission.reviews)).to eq 2
      end
    end
  end

  describe 'team_evaluation_bonus' do
    subject(:bonus) { grade.team_evaluation_bonus }

    let!(:team_submissions) { create_list(:submission, 3, shared_submission_id: shared_submission.id) }
    let(:team_evaluation_rubric) { create(:rubric, peer_assessment: assessment, team_evaluation: true) }
    let(:rubric_options) do
      options = []
      team_submissions.each_with_index do |_, i|
        options << create(:rubric_option, rubric: team_evaluation_rubric, points: i + 1)
      end
      options
    end

    let!(:team_evaluation_reviews) do
      reviews = []
      team_submissions.each_with_index do |s, i|
        reviews << create(:review,
          submission_id: submission.id,
          step_id: assessment.self_assessment_step.id,
          user_id: s.user_id,
          submitted: true,
          optionIDs: [rubric_options[i].id])
      end
      reviews
    end

    it 'computes correct number of bonus points' do
      bonus
      # (1 + 2 + 3)/1/3/3
      expect(grade.reload.bonus_points).to include ['team_evaluation', '0.7']
    end

    context 'with submitted reviews' do
      before do
        team_evaluation_reviews.each do |review|
          review.update submitted: true
        end
      end

      it 'computes correct number of bonus points' do
        bonus
        # (1 + 2 + 3)/1/3/3
        expect(grade.reload.bonus_points).to include ['team_evaluation', '0.7']
      end
    end
  end

  # The participants should be allowed to asked for a regrading if there is no consensus about the points.
  # For each rubric, at least half of the reviewers should have given the same amount of points.
  # Also allow the participants to ask for a regrading if they have received less than three reviews
  describe '.no_consensus_in_reviews?' do
    let(:assessment) { create(:peer_assessment, :with_steps, :with_many_rubrics, id: assessment_id) }

    context 'with less than three reviews' do
      before do
        2.times do |i|
          create(:review, :as_submitted,
            submission_id: submission.id,
            step_id: assessment.grading_step.id,
            user_id: SecureRandom.uuid,
            optionIDs: [assessment.rubrics.first.rubric_options[i].id, assessment.rubrics.second.rubric_options[i].id, assessment.rubrics.third.rubric_options[i].id])
        end
      end

      it 'allows the student to ask for regrading' do
        expect(grade.regradable?).to be true
      end
    end

    context 'with three or more reviews and more than half of the reviewers having achieved consensus in each rubric' do
      before do
        2.times do |i|
          create(:review, :as_submitted,
            submission_id: submission.id,
            step_id: assessment.grading_step.id,
            user_id: SecureRandom.uuid,
            optionIDs: [assessment.rubrics.first.rubric_options[i].id, assessment.rubrics.second.rubric_options[i].id, assessment.rubrics.third.rubric_options[i].id])
        end

        3.times do |_i|
          create(:review, :as_submitted,
            submission_id: submission.id,
            step_id: assessment.grading_step.id,
            user_id: SecureRandom.uuid,
            optionIDs: [assessment.rubrics.first.rubric_options[2].id, assessment.rubrics.second.rubric_options[2].id, assessment.rubrics.third.rubric_options[2].id])
        end
      end

      it 'denies the student to ask for regrading' do
        expect(grade.regradable?).to be false
      end
    end

    context 'with three or more reviews and only half (or less) of the reviewers having achieved consensus in each rubric' do
      before do
        2.times do |i|
          create(:review, :as_submitted,
            submission_id: submission.id,
            step_id: assessment.grading_step.id,
            user_id: SecureRandom.uuid,
            optionIDs: [assessment.rubrics.first.rubric_options[i].id, assessment.rubrics.second.rubric_options[i].id, assessment.rubrics.third.rubric_options[i].id])
        end

        2.times do |_i|
          create(:review, :as_submitted,
            submission_id: submission.id,
            step_id: assessment.grading_step.id,
            user_id: SecureRandom.uuid,
            optionIDs: [assessment.rubrics.first.rubric_options[2].id, assessment.rubrics.second.rubric_options[2].id, assessment.rubrics.third.rubric_options[2].id])
        end
      end

      it 'allows the student to ask for regrading' do
        expect(grade.regradable?).to be true
      end
    end
  end

  describe '.no_consensus_in_reviews? with identical points' do
    let(:assessment) { create(:peer_assessment, :with_steps, :with_rubrics_with_identical_points_for_each_option, id: assessment_id) }

    context 'with a rubric where all options provide the same amount of points' do
      before do
        # selected six different options but all options provide the same amount of points
        6.times do |i|
          create(:review, :as_submitted,
            submission_id: submission.id,
            step_id: assessment.grading_step.id,
            user_id: SecureRandom.uuid,
            optionIDs: [assessment.rubrics.first.rubric_options[i].id, assessment.rubrics.second.rubric_options[i].id, assessment.rubrics.third.rubric_options[i].id])
        end
      end

      it 'allows the student to ask for regrading' do
        expect(grade.regradable?).to be false
      end
    end
  end
end
# rubocop:enable all
