# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Questions: Delete', type: :request do
  subject(:deletion) { api.rel(:question).delete({id: question.id}).value! }

  let(:api) { Restify.new(quiz_service_url).get.value! }
  let!(:question) { create(:'quiz_service/multiple_choice_question', text:, explanation:) }
  let(:text) { "Headline\ns3://xikolo-quiz/quizzes/1/1/test.jpg" }
  let(:explanation) { "Headline\ns3://xikolo-quiz/quizzes/1/2/foo.jpg" }

  let!(:text_file_delete_stub) do
    stub_request(:delete, 'https://s3.xikolo.de/xikolo-quiz/quizzes/1/1/test.jpg')
  end

  let!(:explanation_file_delete_stub) do
    stub_request(:delete, 'https://s3.xikolo.de/xikolo-quiz/quizzes/1/2/foo.jpg')
  end

  before do
    Stub.service(:course, build(:'course:root'))
    Stub.request(
      :course, :get, '/items',
      query: {content_id: question.quiz_id}
    ).to_return Stub.json([
      {id: '53d99410-28c1-4516-8ef5-49ed0e593918'},
    ])
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: nil)
    ).to_return Stub.json({max_points: nil})
  end

  it { is_expected.to respond_with :no_content }

  it 'removes the question' do
    expect { deletion }.to change(QuizService::Question, :count).from(1).to(0)
  end

  it 'deletes the question\'s rich text object' do
    deletion
    expect(text_file_delete_stub).to have_been_requested
  end

  it 'deletes the explanation\'s rich text object' do
    deletion
    expect(explanation_file_delete_stub).to have_been_requested
  end
end
