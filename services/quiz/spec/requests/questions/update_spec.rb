# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Questions: Update', type: :request do
  subject(:modification) { api.rel(:question).put(params, id: question.id).value! }

  before do
    Stub.service(
      :course,
      items_url: 'http://course.xikolo.tld/items',
      item_url: 'http://course.xikolo.tld/items/{id}'
    )
    Stub.request(
      :course, :get, '/items',
      query: {content_id: question.quiz_id}
    ).to_return Stub.json([
      {id: '53d99410-28c1-4516-8ef5-49ed0e593918', max_points: 10.0},
    ])
  end

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { {points: 10.0, shuffle_answers: true} }
  let(:quiz) { create(:quiz) }
  let(:question) { create(:multiple_choice_question, quiz:) }
  let(:qid) { UUID4(quiz.id).to_s(format: :base62) }

  let!(:item_update_request) do
    Stub.request(
      :course, :patch, '/items/53d99410-28c1-4516-8ef5-49ed0e593918',
      body: hash_including(max_points: 11.0)
    ).to_return Stub.json({max_points: 11.0})
  end

  it { is_expected.to respond_with :no_content }

  context 'when setting the question points' do
    let(:params) { {points: new_points} }

    context 'with the old value' do
      let(:new_points) { 10.0 }

      it 'does not update the item\'s max_points' do
        modification
        expect(item_update_request).not_to have_been_requested
      end
    end

    context 'with a new value' do
      let(:new_points) { 11.0 }

      it 'updates the item\'s max_points' do
        modification
        expect(item_update_request).to have_been_requested
      end
    end
  end

  context 'text with file upload references' do
    let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:params) { super().merge text: }

    it 'stores valid upload and updates resource' do
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
      expect { modification }.to change { question.reload.text }
      expect(question.text).to include 's3://xikolo-quiz/quizzes'
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

      expect { modification }.to raise_error(Restify::ClientError) do |error|
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

      expect { modification }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'text' => ['rtfile_error']
      end
    end
  end

  context 'explanation with file upload references' do
    let(:explanation) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:params) { super().merge explanation: }

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
      expect { modification }.to change { question.reload.explanation }
      expect(question.explanation).to include 's3://xikolo-quiz/quizzes'
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

      expect { modification }.to raise_error(Restify::ClientError) do |error|
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

      expect { modification }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'explanation' => ['rtfile_error']
      end
    end
  end
end
