# frozen_string_literal: true

require 'spec_helper'

describe QuizService::Regrading::UpdateCourseResults, type: :model do
  subject(:update_results) { described_class.new(Logger.new(IO::NULL), quiz.id) }

  let!(:quiz) { create(:'quiz_service/quiz') }
  let!(:question) { create(:'quiz_service/free_text_question', quiz:, points: 5) }
  let!(:answer) { create(:'quiz_service/free_text_answer', question:, text: 'foo') }

  let!(:correct_submission) do
    create(:'quiz_service/quiz_submission', :submitted, quiz:).tap do |submission|
      create(:'quiz_service/quiz_submission_question', quiz_submission: submission, quiz_question_id: question.id, points: nil).tap do |submission_question|
        create(:'quiz_service/quiz_submission_free_text_answer', quiz_answer_id: answer.id, quiz_submission_question: submission_question, user_answer_text: 'foo')
      end
    end
  end

  let!(:wrong_submission) do
    create(:'quiz_service/quiz_submission', :submitted, quiz:).tap do |submission|
      create(:'quiz_service/quiz_submission_question', quiz_submission: submission, quiz_question_id: question.id, points: nil).tap do |submission_question|
        create(:'quiz_service/quiz_submission_free_text_answer', quiz_answer_id: answer.id, quiz_submission_question: submission_question, user_answer_text: 'bar')
      end
    end
  end

  let!(:load_item) do
    Stub.request(
      :course, :get, '/items',
      query: {content_id: quiz.id}
    ).to_return Stub.json([{id: item_id}])
  end
  let!(:send_results) do
    Stub.request(
      :course, :put, Addressable::Template.new('/results/{id}')
    )
  end
  let(:item_id) { generate(:item_id) }

  it 'sends the points to xi-course' do
    update_results.run!

    expect(send_results).to have_been_requested.twice
    expect(
      send_results.with(body: hash_including(user_id: correct_submission.user_id, points: 5.0))
    ).to have_been_requested.once
    expect(
      send_results.with(body: hash_including(user_id: wrong_submission.user_id, points: 0.0))
    ).to have_been_requested.once
  end

  it 'loads the item information only once' do
    update_results.run!

    expect(load_item).to have_been_requested.once
  end
end
