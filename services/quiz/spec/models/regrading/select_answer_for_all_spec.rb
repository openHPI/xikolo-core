# frozen_string_literal: true

require 'spec_helper'

describe Regrading::SelectAnswerForAll, type: :model do
  let!(:quiz) { create(:quiz) }
  let!(:quiz_question) { create(:multiple_answer_question, quiz:, points: 5) }
  let!(:selected_answer) { create(:answer, question: quiz_question, correct: true, text: 'Correct answer 1') }
  let!(:answer_to_select) { create(:answer, question: quiz_question, correct: true, text: 'Correct answer 2') }

  # The first user had already selected both answers
  let!(:quiz_submission1) do
    create(:quiz_submission, quiz:, user_id: generate(:user_id)).tap do |submission|
      create(
        :quiz_submission_question, quiz_submission: submission, quiz_question_id: quiz_question.id, points: 5.0
      ).tap do |question|
        create(:quiz_submission_selectable_answer, quiz_answer_id: answer_to_select.id, quiz_submission_question: question)
        create(:quiz_submission_selectable_answer, quiz_answer_id: selected_answer.id, quiz_submission_question: question)
      end
    end
  end

  # The second user had only selected one of the correct answers
  let!(:quiz_submission2) do
    create(:quiz_submission, quiz:, user_id: generate(:user_id)).tap do |submission|
      create(
        :quiz_submission_question, quiz_submission: submission, quiz_question_id: quiz_question.id, points: 2.5
      ).tap do |question|
        create(:quiz_submission_selectable_answer, quiz_answer_id: selected_answer.id, quiz_submission_question: question)
      end
    end
  end

  it 'creates the answer for all questions without the selected answer' do
    question = QuizSubmissionQuestion.find_by(quiz_submission_id: quiz_submission2.id)
    answer = question.quiz_submission_answers.where(quiz_answer_id: answer_to_select.id)

    expect do
      Regrading::SelectAnswerForAll.new(answer_to_select).run!
    end.to change { answer.count }.from(0).to(1)
  end

  it 'does nothing for all questions with the selected answer' do
    question = QuizSubmissionQuestion.find_by(quiz_submission_id: quiz_submission1.id)
    answer = question.quiz_submission_answers.where(quiz_answer_id: answer_to_select.id)

    expect do
      Regrading::SelectAnswerForAll.new(answer_to_select).run!
    end.not_to change { answer.count }
  end

  it 'does not change points for submissions which already have the selected answer' do
    expect do
      Regrading::SelectAnswerForAll.new(answer_to_select).run!
    end.not_to change { quiz_submission1.reload.points }
  end

  it 'resets the points for submissions without the selected answer' do
    expect do
      Regrading::SelectAnswerForAll.new(answer_to_select).run!
    end.to change { quiz_submission2.reload.points }.from(2.5).to(5.0)
  end

  it 'does not change the points for each submission when run in dry mode' do
    Regrading::SelectAnswerForAll.new(answer_to_select, dry: true).run!

    expect(quiz_submission1.reload.points).to eq 5.0
    expect(quiz_submission2.reload.points).to eq 2.5
  end

  it 'triggers recalculation of question statistics' do
    Sidekiq::Testing.fake!

    expect do
      Regrading::SelectAnswerForAll.new(answer_to_select).run!
    end.to change(UpdateQuestionStatisticsWorker.jobs, :size).by(1)
  end
end
