# frozen_string_literal: true

require 'spec_helper'

describe QuizService::Regrading::RemoveAnswer, type: :model do
  let!(:quiz) { create(:'quiz_service/quiz') }
  let!(:quiz_question) { create(:'quiz_service/multiple_answer_question', quiz:, points: 3) }
  let!(:answer1) { create(:'quiz_service/answer', question: quiz_question, correct: true) }
  let!(:answer2) { create(:'quiz_service/answer', question: quiz_question, correct: true) }

  # This answer was originally marked as incorrect, so we want to delete it.
  # Users' responses to this answer will no longer be counted.
  let!(:misleading_answer) { create(:'quiz_service/answer', question: quiz_question, correct: false) }

  # This user had selected both correct answers and the misleading, but incorrect one.
  let!(:submission) do
    create(:'quiz_service/quiz_submission', quiz:).tap do |submission|
      create(:'quiz_service/quiz_submission_question', quiz_submission: submission, quiz_question_id: quiz_question.id, points: 1.5).tap do |question|
        create(:'quiz_service/quiz_submission_selectable_answer', quiz_answer_id: answer1.id, quiz_submission_question: question)
        create(:'quiz_service/quiz_submission_selectable_answer', quiz_answer_id: answer2.id, quiz_submission_question: question)
        create(:'quiz_service/quiz_submission_selectable_answer', quiz_answer_id: misleading_answer.id, quiz_submission_question: question)
      end
    end
  end

  it 'recalculates the points correctly after regrading' do
    expect do
      described_class.new(misleading_answer).run!
    end.to change { submission.reload.points }.from(1.5).to(3)
  end

  it 'deletes the actual quiz answer' do
    expect do
      described_class.new(misleading_answer).run!
    end.to change(misleading_answer, :destroyed?).from(false).to(true)
  end

  it 'deletes the incorrect submission answer' do
    expect do
      described_class.new(misleading_answer).run!
    end.to change { QuizService::QuizSubmissionAnswer.where(quiz_answer_id: misleading_answer.id).count }.from(1).to(0)
  end

  it 'does not regrade the submission when run in dry mode' do
    described_class.new(misleading_answer, dry: true).run!

    expect(QuizService::Answer.count).to eq 3
    expect(QuizService::QuizSubmissionAnswer.count).to eq 3
    expect(submission.reload.points).to eq 1.5
  end

  it 'triggers recalculation of question statistics' do
    Sidekiq::Testing.fake!

    expect do
      described_class.new(misleading_answer).run!
    end.to change(QuizService::UpdateQuestionStatisticsWorker.jobs, :size).by(1)
  end

  describe 'loss of points is possible' do
    # The user again selected all answers. Two of them were marked as correct,
    # but one of them was the misleading one.
    let!(:misleading_answer) { create(:'quiz_service/answer', question: quiz_question, correct: true) }

    before { answer2.update(correct: false) }

    it 'revokes points when necessary' do
      expect do
        described_class.new(misleading_answer).run!
      end.to change { submission.reload.points }.from(1.5).to(0)
    end
  end
end
