# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Questions: Create', type: :request do
  subject(:creation) { api.rel(:questions).post(payload).value! }

  let(:api) { restify_with_headers(quiz_service_url).get.value! }

  let(:payload) { attributes_for(:'quiz_service/multiple_choice_question', quiz_id: quiz.id, type: 'MultipleChoiceQuestion') }
  let(:quiz) { create(:'quiz_service/quiz') }
  let(:qid) { UUID4(quiz.id).to_s(format: :base62) }

  before do
    Stub.request(
      :course, :get, '/items',
      query: {content_id: payload[:quiz_id]}
    ).to_return Stub.json([
      {id: '53d99410-28c1-4516-8ef5-49ed0e593918'},
    ])
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: 10.0)
    ).to_return Stub.json({max_points: 10.0})
  end

  it { is_expected.to respond_with :created }

  it 'creates a new question' do
    expect { creation }.to change(QuizService::Question, :count).from(0).to(1)
  end

  context 'without a type attribute' do
    let(:payload) { super().except(:type) }

    it 'responds with 422 Unprocessable Entity' do
      expect { creation }.to raise_error(Restify::ClientError) do |err|
        expect(err.status).to eq :unprocessable_content
      end
    end
  end

  context 'text with file upload references' do
    let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:payload) { super().merge text: }

    it 'stores valid upload and creates a new resource' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_question_text',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-quiz
                       /quizzes/#{qid}/[0-9a-zA-Z]+_foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { creation }.to change(QuizService::Question, :count).from(0).to(1)
      expect(QuizService::Question.last.text).to include 's3://xikolo-quiz/quizzes'
    end

    it 'rejects invalid upload and does not creates a new page' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_question_text',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'text' => ['rtfile_rejected']
      end
    end

    it 'rejects upload on storage errors' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_question_text',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-quiz
                       /quizzes/#{qid}/[0-9a-zA-Z]+_foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'text' => ['rtfile_error']
      end
    end
  end

  context 'explanation with file upload references' do
    let(:explanation) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:payload) { super().merge explanation: }

    it 'stores valid upload and creates a new richexplanation' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_question_explanation',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-quiz
                       /quizzes/#{qid}/[0-9a-zA-Z]+_foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { creation }.to change(QuizService::Question, :count).from(0).to(1)
      expect(QuizService::Question.last.explanation).to include 's3://xikolo-quiz/quizzes'
    end

    it 'rejects invalid upload and does not creates a new page' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_question_explanation',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'explanation' => ['rtfile_rejected']
      end
    end

    it 'rejects upload on storage errors' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_question_explanation',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-quiz
                       /quizzes/#{qid}/[0-9a-zA-Z]+_foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'explanation' => ['rtfile_error']
      end
    end
  end
end
