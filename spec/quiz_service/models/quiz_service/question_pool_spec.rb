# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Quiz question pools', type: :model do
  let(:quiz) do
    create(:'quiz_service/quiz', question_pool: true, displayed_question_count: 10, allowed_attempts: 2)
  end

  def add_pool_questions(easy: 10, mid: 10, hard: 10)
    [[easy, 1], [mid, 2], [hard, 3]].each do |count, points|
      create_list(:'quiz_service/multiple_choice_question', count, quiz:, points:)
    end
  end

  describe '#required_question_counts_by_difficulty' do
    it 'returns no requirements for counts that cannot form a complete batch' do
      [nil, 0, 9, 11].each do |question_count|
        quiz.displayed_question_count = question_count

        expect(quiz.send(:required_question_counts_by_difficulty)).to eq({})
      end
    end

    it 'returns the difficulty counts for each batch' do
      quiz.displayed_question_count = 20

      expect(quiz.send(:required_question_counts_by_difficulty)).to eq(easy: 6, mid: 6, hard: 8)
    end
  end

  describe '#question_pool_status' do
    it 'provides the same fulfillment state used to validate a question pool' do
      add_pool_questions(easy: 23, mid: 3, hard: 4)

      expect(quiz.question_pool_status).to have_attributes(
        displayed_question_count: hash_including(message: :questions_per_learner, fulfilled: true),
        pool_size: hash_including(message: :pool_size, fulfilled: true),
        difficulties: include(hash_including(message: :difficulty,
          options: hash_including(difficulty: :easy, required_count: 3))),
        question_types: hash_including(message: :question_types, fulfilled: true)
      )
      expect(quiz.question_pool_status).to be_valid
      expect(quiz.valid_question_pool?).to be(true)
    end

    it 'reports unmet criteria and uses them for validation errors' do
      add_pool_questions(easy: 2, mid: 3, hard: 4)

      expect(quiz.question_pool_status.difficulties).to include(
        hash_including(message: :difficulty, fulfilled: false, options: hash_including(difficulty: :easy))
      )
      expect(quiz.valid_question_pool?).to be(false)
      expect(quiz.errors.of_kind?(:questions, :insufficient_exam_questions_for_difficulty)).to be(true)
    end
  end

  describe 'authoring validation' do
    it 'is only available for exams' do
      create(:'course_service/item', :quiz, content_id: quiz.id, exercise_type: 'selftest', published: false)
      quiz.reload

      expect(quiz).not_to be_valid
      expect(quiz.errors.of_kind?(:question_pool, :only_available_for_exam_quizzes)).to be(true)
    end

    it 'accepts only single- and multi-select questions' do
      expect(build(:'quiz_service/free_text_question', quiz:)).not_to be_valid
      expect(build(:'quiz_service/essay_question', quiz:)).not_to be_valid
      expect(build(:'quiz_service/multiple_choice_question', quiz:)).to be_valid
      expect(build(:'quiz_service/multiple_answer_question', quiz:)).to be_valid
    end

    it 'requires a positive multiple of ten as the displayed count' do
      quiz.displayed_question_count = 11

      expect(quiz.valid_question_pool?).to be(false)
      expect(quiz.errors.of_kind?(:displayed_question_count, :invalid_exam_question_count)).to be(true)
    end

    it 'does not report a pool-size error when an invalid displayed count still has the matching pool size' do
      quiz.displayed_question_count = 11
      add_pool_questions(easy: 11, mid: 11, hard: 11)

      expect(quiz.valid_question_pool?).to be(false)
      expect(quiz.errors.of_kind?(:questions, :invalid_exam_pool_size)).to be(false)
    end

    it 'requires exactly three times as many pool questions' do
      add_pool_questions(easy: 9, mid: 10, hard: 10)

      expect(quiz.valid_question_pool?).to be(false)
      expect(quiz.errors.of_kind?(:questions, :invalid_exam_pool_size)).to be(true)
      expect(quiz.errors.details[:questions]).to include(error: :invalid_exam_pool_size, count: 30)
    end

    it 'requires enough easy questions' do
      add_pool_questions(easy: 2, mid: 3, hard: 4)

      expect(quiz.valid_question_pool?).to be(false)
      expect(quiz.errors.of_kind?(:questions, :insufficient_exam_questions_for_difficulty)).to be(true)
    end

    it 'requires enough mid questions' do
      add_pool_questions(easy: 3, mid: 2, hard: 4)

      expect(quiz.valid_question_pool?).to be(false)
      expect(quiz.errors.of_kind?(:questions, :insufficient_exam_questions_for_difficulty)).to be(true)
    end

    it 'requires enough hard questions' do
      add_pool_questions(easy: 3, mid: 3, hard: 3)

      expect(quiz.valid_question_pool?).to be(false)
      expect(quiz.errors.of_kind?(:questions, :insufficient_exam_questions_for_difficulty)).to be(true)
    end
  end

  describe '#attempt!' do
    let(:first_user) { create(:'account_service/user').id }
    let(:second_user) { create(:'account_service/user').id }

    before { add_pool_questions }

    it 'randomly persists exactly the configured number of questions' do
      submission = quiz.attempt!(first_user)

      expect(submission.quiz_submission_questions.count).to eq(10)
      expect(submission.quiz_submission_questions.pluck(:quiz_question_id)).to all be_in(quiz.questions.ids)
    end

    it 'persists three easy, three mid, and four hard questions' do
      submission = quiz.attempt!(first_user)
      selected_points = QuizService::Question
        .where(id: submission.quiz_submission_questions.select(:quiz_question_id))
        .pluck(:points)
        .map(&:to_i)

      expect(selected_points.tally).to eq(1 => 3, 2 => 3, 3 => 4)
      expect(submission.max_points).to eq(21)
    end

    it 'scales the difficulty set for multiples of ten questions' do
      quiz.update!(displayed_question_count: 20)
      quiz.questions.destroy_all
      add_pool_questions(easy: 20, mid: 20, hard: 20)

      submission = quiz.attempt!(first_user)
      selected_points = QuizService::Question
        .where(id: submission.quiz_submission_questions.select(:quiz_question_id))
        .pluck(:points)
        .map(&:to_i)

      expect(selected_points.tally).to eq(1 => 6, 2 => 6, 3 => 8)
    end

    it 'keeps the question order on refreshes and resumes' do
      submission = quiz.attempt!(first_user)
      question_ids = submission.quiz_submission_questions.order(:position).pluck(:quiz_question_id)

      expect(quiz.attempt!(first_user)).to eq(submission)
      expect(submission.reload.quiz_submission_questions.order(:position).pluck(:quiz_question_id)).to eq(question_ids)
    end

    it 'uses the same question set for the second attempt' do
      first_attempt = quiz.attempt!(first_user)
      question_ids = first_attempt.quiz_submission_questions.order(:position).pluck(:quiz_question_id)
      first_attempt.update!(quiz_submission_time: Time.zone.now)

      second_attempt = quiz.attempt!(first_user)

      expect(second_attempt.quiz_submission_questions.order(:position).pluck(:quiz_question_id)).to eq(question_ids)
      expect(quiz.reload.allowed_attempts).to eq(2)
    end

    it 'selects an independent set for another learner' do
      first_attempt = quiz.attempt!(first_user)
      second_attempt = quiz.attempt!(second_user)

      expect(second_attempt.quiz_submission_questions.order(:position).pluck(:quiz_question_id))
        .not_to eq(first_attempt.quiz_submission_questions.order(:position).pluck(:quiz_question_id))
    end

    it 'does not start an invalid exam' do
      quiz.questions.limit(1).destroy_all

      attempt = quiz.attempt!(first_user)

      expect(attempt).not_to be_persisted
      expect(attempt.errors.of_kind?(:questions, :invalid_exam_pool_size)).to be(true)
    end
  end
end
