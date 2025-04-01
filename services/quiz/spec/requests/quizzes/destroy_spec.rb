# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Quiz: Destroy', type: :request do
  subject(:destroy) { api.rel(:quiz).delete({id: quiz.id}).value! }

  let(:api) { Restify.new(:test).get.value! }
  let!(:quiz) { create(:quiz, instructions: 's3://xikolo-quiz/quizzes/1/1/test.jpg') }
  let!(:file_deletion) do
    stub_request(:delete, 'https://s3.xikolo.de/xikolo-quiz/quizzes/1/1/test.jpg')
  end

  it 'destroys the quiz' do
    expect { destroy }.to change(Quiz, :count).from(1).to(0)
    expect(destroy).to respond_with :no_content
  end

  it 'deletes referenced files from instructions markup' do
    destroy
    expect(file_deletion).to have_been_requested
  end

  context 'with submissions' do
    before do
      submission = create(:quiz_submission, :submitted, quiz:)
      question = create(:quiz_submission_question, quiz_submission: submission)
      create(:quiz_submission_answer, quiz_submission_question: question)
      create(:quiz_submission_snapshot, quiz_submission: submission)
    end

    it 'deletes the corresponding submissions' do
      expect { destroy }.to change(QuizSubmission, :count).from(1).to(0)
    end

    it 'deletes all related data for a submission' do
      expect { destroy }.to change(QuizSubmissionQuestion, :count).from(1).to(0)
        .and change(QuizSubmissionAnswer, :count).from(1).to(0)
        .and change(QuizSubmissionSnapshot, :count).from(1).to(0)
    end
  end

  context 'with additional quiz attempts' do
    before { create(:additional_quiz_attempt, quiz_id: quiz.id) }

    it 'deletes the corresponding attempts' do
      expect { destroy }.to change(AdditionalQuizAttempt, :count).from(1).to(0)
    end
  end
end
