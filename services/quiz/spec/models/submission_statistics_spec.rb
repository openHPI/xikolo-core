# frozen_string_literal: true

require 'spec_helper'

describe SubmissionStatistics, type: :model do
  subject { described_class.new(quiz) }

  let(:quiz) { create(:quiz) }

  context 'base stats' do
    before do
      question = create(:multiple_choice_question, quiz:, points: 10)

      submission1 = create(
        :quiz_submission,
        :submitted,
        quiz:,
        user_id: generate(:user_id)
      )
      submission2 = create(
        :quiz_submission,
        :submitted,
        quiz:,
        user_id: generate(:user_id)
      )

      create(
        :quiz_submission_question,
        quiz_question_id: question.id,
        quiz_submission: submission1,
        points: 10
      )
      create(
        :quiz_submission_question,
        quiz_question_id: question.id,
        quiz_submission: submission2,
        points: 5
      )
    end

    describe '#total_submissions' do
      subject(:total_submissions) do
        described_class.new(quiz).total_submissions
      end

      it 'returns correct result' do
        expect(total_submissions).to eq(2)
      end
    end

    describe '#total_submissions_distinct' do
      subject(:total_submissions_distinct) do
        described_class.new(quiz).total_submissions_distinct
      end

      it 'returns correct result' do
        expect(total_submissions_distinct).to eq(2)
      end
    end

    describe '#max_points' do
      subject(:max_points) do
        described_class.new(quiz).max_points
      end

      it 'returns correct result' do
        expect(max_points).to eq(10)
      end
    end

    describe '#avg_points' do
      subject(:avg_points) do
        described_class.new(quiz).avg_points
      end

      it 'returns correct result' do
        expect(avg_points).to eq(7.5)
      end
    end
  end

  describe '#unlimited_time' do
    subject(:unlimited_time) do
      described_class.new(quiz).unlimited_time
    end

    it 'returns correct result' do
      expect(unlimited_time).to be(false)
    end
  end

  describe '#avg_submit_duration' do
    subject(:avg_submit_duration) do
      described_class.new(quiz).avg_submit_duration
    end

    before do
      create(
        :quiz_submission,
        :submitted,
        quiz:,
        created_at: DateTime.new(2000, 1, 1, 10, 0, 0),
        quiz_submission_time: DateTime.new(2000, 1, 1, 11, 0, 0)
      )
      create(
        :quiz_submission,
        :submitted,
        quiz:,
        created_at: DateTime.new(2000, 1, 1, 10, 0, 0),
        quiz_submission_time: DateTime.new(2000, 1, 1, 10, 30, 0)
      )
    end

    it 'returns correct duration' do
      expect(avg_submit_duration).to eq(45.minutes.to_i) # 45 min in s
    end
  end

  describe '#submissions_over_time' do
    subject(:submissions_over_time) do
      described_class.new(quiz).submissions_over_time
    end

    before do
      create(
        :quiz_submission,
        :submitted,
        quiz:,
        quiz_submission_time: DateTime.new(2000, 1, 1, 10)
      )
      create(
        :quiz_submission,
        :submitted,
        quiz:,
        quiz_submission_time: DateTime.new(2000, 1, 1, 11)
      )
      create(
        :quiz_submission,
        :submitted,
        quiz:,
        quiz_submission_time: DateTime.new(2000, 1, 2, 12)
      )

      # create another quiz with submissions that should be ignored
      another_quiz = create(:quiz)
      create(
        :quiz_submission,
        :submitted,
        quiz: another_quiz,
        quiz_submission_time: DateTime.new(2000, 1, 1, 10)
      )
      create(
        :quiz_submission,
        :submitted,
        quiz: another_quiz,
        quiz_submission_time: DateTime.new(2000, 1, 1, 11)
      )
      create(
        :quiz_submission,
        :submitted,
        quiz: another_quiz,
        quiz_submission_time: DateTime.new(2000, 1, 2, 12)
      )
    end

    it 'includes timestamps per hour with counts' do
      expect(submissions_over_time.as_json).to include(
        '2000-01-01 10:00:00 UTC' => 1,
        '2000-01-01 11:00:00 UTC' => 1,
        '2000-01-01 12:00:00 UTC' => 0,
        '2000-01-01 13:00:00 UTC' => 0,
        '2000-01-01 14:00:00 UTC' => 0,
        '2000-01-01 15:00:00 UTC' => 0,
        '2000-01-01 16:00:00 UTC' => 0,
        '2000-01-01 17:00:00 UTC' => 0,
        '2000-01-01 18:00:00 UTC' => 0,
        '2000-01-01 19:00:00 UTC' => 0,
        '2000-01-01 20:00:00 UTC' => 0,
        '2000-01-01 21:00:00 UTC' => 0,
        '2000-01-01 22:00:00 UTC' => 0,
        '2000-01-01 23:00:00 UTC' => 0,
        '2000-01-02 00:00:00 UTC' => 0,
        '2000-01-02 01:00:00 UTC' => 0,
        '2000-01-02 02:00:00 UTC' => 0,
        '2000-01-02 03:00:00 UTC' => 0,
        '2000-01-02 04:00:00 UTC' => 0,
        '2000-01-02 05:00:00 UTC' => 0,
        '2000-01-02 06:00:00 UTC' => 0,
        '2000-01-02 07:00:00 UTC' => 0,
        '2000-01-02 08:00:00 UTC' => 0,
        '2000-01-02 09:00:00 UTC' => 0,
        '2000-01-02 10:00:00 UTC' => 0,
        '2000-01-02 11:00:00 UTC' => 0,
        '2000-01-02 12:00:00 UTC' => 1
      )
    end

    context 'with more than three days' do
      before do
        create(
          :quiz_submission,
          :submitted,
          quiz:,
          quiz_submission_time: DateTime.new(2000, 1, 3, 10)
        )
        create(
          :quiz_submission,
          :submitted,
          quiz:,
          quiz_submission_time: DateTime.new(2000, 1, 6, 11)
        )
      end

      it 'includes timestamps per day with counts' do
        expect(submissions_over_time.as_json).to include(
          '2000-01-01' => 2,
          '2000-01-02' => 1,
          '2000-01-03' => 1,
          '2000-01-04' => 0,
          '2000-01-05' => 0,
          '2000-01-06' => 1
        )
      end
    end
  end

  describe '#box_plot_distributions' do
    subject { super().box_plot_distributions }

    let(:other_quiz) { create(:quiz) }

    before do
      allow(quiz).to receive(:max_points).and_return(10)
      allow(other_quiz).to receive(:max_points).and_return(100)

      submission1 = create(:quiz_submission, :submitted, quiz_id: quiz.id)
      submission2 = create(:quiz_submission, :submitted, quiz_id: quiz.id)
      submission3 = create(:quiz_submission, :submitted, quiz_id: quiz.id)
      submission4 = create(:quiz_submission, :submitted, quiz_id: quiz.id)
      submission5 = create(:quiz_submission, :submitted, quiz_id: quiz.id)

      other_submission =
        create(:quiz_submission, :submitted, quiz_id: other_quiz.id)

      [0, 0, 0].each do |p|
        create(:quiz_submission_question,
          quiz_submission_id: submission1.id, points: p)
      end
      [0, 1, 1].each do |p|
        create(:quiz_submission_question,
          quiz_submission_id: submission2.id, points: p)
      end
      [2, 2, 1].each do |p|
        create(:quiz_submission_question,
          quiz_submission_id: submission3.id, points: p)
      end
      [2, 2, 4].each do |p|
        create(:quiz_submission_question,
          quiz_submission_id: submission4.id, points: p)
      end
      [4, 3, 3].each do |p|
        create(:quiz_submission_question,
          quiz_submission_id: submission5.id, points: p)
      end

      create(:quiz_submission_question,
        quiz_submission_id: other_submission.id, points: 100)
    end

    it { is_expected.to eq(min: 0.0, q1: 0.1, median: 0.5, q3: 0.9, max: 1.0) }
  end

  describe '#questions_base_stats' do
    subject(:questions_base_stats) do
      described_class.new(quiz).questions_base_stats
    end

    let(:question) do
      create(:multiple_choice_question, quiz:, points: 10)
    end

    let!(:question_without_submissions) do
      create(:multiple_answer_question, quiz:, points: 5)
    end

    let!(:question_zero_points) do
      create(:multiple_choice_question, quiz:, points: 0)
    end

    before do
      submission1 = create(:quiz_submission, :submitted, quiz:)
      submission2 = create(:quiz_submission, :submitted, quiz:)

      # First question
      answer1 = create(:answer, question:, correct: true)
      answer2 = create(:answer, question:, correct: false)

      qsq1 = create(
        :quiz_submission_question,
        quiz_question_id: question.id,
        quiz_submission: submission1,
        points: 10
      )
      qsq2 = create(
        :quiz_submission_question,
        quiz_question_id: question.id,
        quiz_submission: submission2,
        points: 5
      )

      create(
        :quiz_submission_answer,
        quiz_answer_id: answer1.id,
        quiz_submission_question: qsq1
      )
      create(
        :quiz_submission_answer,
        quiz_answer_id: answer2.id,
        quiz_submission_question: qsq2
      )
      create(
        :quiz_submission_answer,
        quiz_answer_id: answer2.id,
        quiz_submission_question: qsq2
      )

      # Question with zero points
      answer1 = create(:answer, question: question_zero_points, correct: true)
      answer2 = create(:answer, question: question_zero_points, correct: true)

      q01 = create(
        :quiz_submission_question,
        quiz_question_id: question_zero_points.id,
        quiz_submission: submission1,
        points: 0
      )
      q02 = create(
        :quiz_submission_question,
        quiz_question_id: question_zero_points.id,
        quiz_submission: submission2,
        points: 0
      )

      create(
        :quiz_submission_answer,
        quiz_answer_id: answer1.id,
        quiz_submission_question: q01
      )
      create(
        :quiz_submission_answer,
        quiz_answer_id: answer2.id,
        quiz_submission_question: q02
      )
    end

    it 'returns correct result hash' do
      expect(questions_base_stats.as_json).to contain_exactly(
        {
          id: question.id,
          max_points: 10.0,
          avg_points: 7.5,
          correct_submissions: 1,
          partly_correct_submissions: 1,
          incorrect_submissions: 0,
        }.as_json,
        # Questions without any submissions show up in the results
        {
          id: question_without_submissions.id,
          max_points: 5.0,
          avg_points: 0.0,
          correct_submissions: 0,
          partly_correct_submissions: 0,
          incorrect_submissions: 0,
        }.as_json,
        # Questions with zero points count all submissions as "correct"
        {
          id: question_zero_points.id,
          max_points: 0.0,
          avg_points: 0.0,
          correct_submissions: 2,
          partly_correct_submissions: 0,
          incorrect_submissions: 0,
        }.as_json
      )
    end
  end
end
