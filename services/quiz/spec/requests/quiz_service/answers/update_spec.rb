# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Answers: Update', type: :request do
  subject(:modification) do
    api.rel(:answer).patch(payload, params: {id: answer.id}).value!
  end

  let(:api) { Restify.new(quiz_service_url).get.value! }
  let(:payload) { {correct: true, comment: 'Very Important'} }
  let(:quiz) { create(:'quiz_service/quiz') }
  let(:question) { create(:'quiz_service/multiple_choice_question', quiz:) }
  let(:answer) { create(:'quiz_service/answer', question:) }
  let(:qid) { UUID4(quiz.id).to_s(format: :base62) }

  it { is_expected.to respond_with :no_content }

  it 'modifies the referenced answer' do
    expect { modification }.to change { answer.reload; [answer.correct, answer.comment] }
  end

  context 'text with file upload references' do
    let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:payload) { super().merge text: }

    it 'stores valid upload and updates resource' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_answer_text',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-quiz
                       /quizzes/#{qid}/[0-9a-zA-Z]+_foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { modification }.to change { answer.reload.text }
      expect(answer.text).to include 's3://xikolo-quiz/quizzes'
    end

    it 'rejects invalid upload and does not creates a new page' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_answer_text',
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
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_answer_text',
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
end
