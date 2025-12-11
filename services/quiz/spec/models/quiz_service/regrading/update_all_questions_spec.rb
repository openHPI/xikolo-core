# frozen_string_literal: true

require 'spec_helper'

describe QuizService::Regrading::UpdateAllQuestions, type: :model do
  let!(:quiz) { create(:'quiz_service/quiz') }

  # The achievable points for these questions have been changed by a teacher in the frontend
  let!(:question1) { create(:'quiz_service/free_text_question', quiz:, points: 3, position: 1) }
  let!(:answer1) { create(:'quiz_service/free_text_answer', question: question1, text: 'foo') }
  let!(:question2) { create(:'quiz_service/free_text_question', quiz:, points: 4, position: 2) }
  let!(:answer2) { create(:'quiz_service/free_text_answer', question: question2, text: 'bar') }

  # This user's submission still reflects the grading based on previous distribution of points
  # (1 point for the first question, 2 for the second one)
  let!(:submission) do
    create(:'quiz_service/quiz_submission', quiz:).tap do |submission|
      create(:'quiz_service/quiz_submission_question', quiz_submission: submission, quiz_question_id: question1.id, points: 1.0).tap do |submission_question|
        create(:'quiz_service/quiz_submission_free_text_answer', quiz_answer_id: answer1.id, quiz_submission_question: submission_question, user_answer_text: 'foo')
      end
      create(:'quiz_service/quiz_submission_question', quiz_submission: submission, quiz_question_id: question2.id, points: 2.0).tap do |submission_question|
        create(:'quiz_service/quiz_submission_free_text_answer', quiz_answer_id: answer2.id, quiz_submission_question: submission_question, user_answer_text: 'bar')
      end
    end
  end

  it 'updates the points for the entire submission' do
    expect do
      described_class.new(quiz).run!
    end.to change { submission.reload.points }.from(3).to(7)
  end

  it 'does not update points when run in dry mode' do
    expect do
      described_class.new(quiz, dry: true).run!
    end.not_to change { submission.reload.points }
  end

  it 'triggers recalculation of questions statistics' do
    Sidekiq::Testing.fake!

    expect do
      described_class.new(quiz).run!
    end.to change(QuizService::UpdateQuestionStatisticsWorker.jobs, :size).by(2)
  end
end
