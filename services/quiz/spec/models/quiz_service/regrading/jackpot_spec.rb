# frozen_string_literal: true

require 'spec_helper'

describe QuizService::Regrading::Jackpot, type: :model do
  let!(:quiz) { create(:'quiz_service/quiz') }
  let!(:quiz_question) { create(:'quiz_service/multiple_answer_question', quiz:, points: 3) }
  let!(:correct_answer) { create(:'quiz_service/answer', question: quiz_question, correct: true) }
  let!(:wrong_answer) { create(:'quiz_service/answer', question: quiz_question, correct: false) }

  # This user had selected the correct answer, so they should be unaffected by the regrading.
  let!(:submission1) do
    create(:'quiz_service/quiz_submission', quiz:, user_id: generate(:user_id)).tap do |submission|
      create(:'quiz_service/quiz_submission_question', quiz_submission: submission, quiz_question_id: quiz_question.id, points: 3).tap do |question|
        create(:'quiz_service/quiz_submission_selectable_answer', quiz_answer_id: correct_answer.id, quiz_submission_question: question)
      end
    end
  end

  # This user had selected the incorrect answer, so they should have more points after the regrading.
  let!(:submission2) do
    create(:'quiz_service/quiz_submission', quiz:, user_id: generate(:user_id)).tap do |submission|
      create(:'quiz_service/quiz_submission_question', quiz_submission: submission, quiz_question_id: quiz_question.id, points: 0).tap do |question|
        create(:'quiz_service/quiz_submission_selectable_answer', quiz_answer_id: wrong_answer.id, quiz_submission_question: question)
      end
    end
  end

  # This user did not make any selection for this question, so the quiz submission question needs to be created first.
  let!(:submission3) { create(:'quiz_service/quiz_submission', quiz:, user_id: generate(:user_id)) }

  it 'does not give more points to users who already have full points' do
    expect do
      described_class.new(quiz_question).run!
    end.not_to change { submission1.reload.points }.from(3)
  end

  it 'awards full points to users who would gain points' do
    expect do
      described_class.new(quiz_question).run!
    end.to change { submission2.reload.points }.from(0).to(3)
  end

  it 'awards full points to users who did not answer the question' do
    expect do
      described_class.new(quiz_question).run!
    end.to change { submission3.reload.points }.from(0).to(3)
  end

  it 'does nothing when run in dry mode' do
    described_class.new(quiz_question, dry: true).run!

    expect(submission1.points).to eq 3
    expect(submission2.points).to eq 0
    expect(submission3.points).to eq 0
  end

  it 'triggers recalculation of questions statistics' do
    Sidekiq::Testing.fake!

    expect do
      described_class.new(quiz_question).run!
    end.to change(QuizService::UpdateQuestionStatisticsWorker.jobs, :size).by(1)
  end
end
