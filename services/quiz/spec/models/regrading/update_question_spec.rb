# frozen_string_literal: true

require 'spec_helper'

describe Regrading::UpdateQuestion, type: :model do
  let!(:quiz) { create(:quiz) }
  let!(:question) { create(:free_text_question, quiz:, points: 5) }
  let!(:answer_old) { create(:free_text_answer, question:, text: 'foo') }

  # This user had provided a correct answer, that hadn't yet been stored as a correct answer in the frontend
  let!(:submission) do
    create(:quiz_submission, quiz:).tap do |submission|
      create(:quiz_submission_question, quiz_submission: submission, quiz_question_id: question.id, points: 0.0).tap do |submission_question|
        create(:quiz_submission_free_text_answer, quiz_answer_id: answer_old.id, quiz_submission_question: submission_question, user_answer_text: 'bar')
      end
    end
  end

  # The new answer object
  before { create(:free_text_answer, question:, text: 'bar') }

  it 'awards all points' do
    expect do
      Regrading::UpdateQuestion.new(question).run!
    end.to change { submission.reload.points }.from(0).to(5)
  end

  it 'does not change any points when run in dry mode' do
    expect do
      Regrading::UpdateQuestion.new(question, dry: true).run!
    end.not_to change { submission.reload.points }
  end

  it 'triggers recalculation of question statistics' do
    Sidekiq::Testing.fake!

    expect do
      Regrading::UpdateQuestion.new(question).run!
    end.to change(UpdateQuestionStatisticsWorker.jobs, :size).by(1)
  end
end
