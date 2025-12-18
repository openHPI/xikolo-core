# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Quiz: Update', type: :request do
  subject(:modification) { api.rel(:quiz).patch(payload, params: {id: quiz.id}).value! }

  let(:api) { restify_with_headers(quiz_service_url).get.value! }
  let(:quiz) { create(:'quiz_service/quiz', time_limit_seconds: 60) }
  let(:qid) { UUID4(quiz.id).to_s(format: :base62) }
  let(:payload) { {time_limit_seconds: 4242} }

  it { is_expected.to respond_with :no_content }

  it 'modifies the existing quiz' do
    expect { modification; quiz.reload }.to change(quiz, :time_limit_seconds).from(60).to(4242)
  end

  context 'instructions with file upload references' do
    let(:instructions) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:payload) { super().merge instructions: }

    it 'stores valid upload and updates quiz' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_quiz_instructions',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-quiz
                       /quizzes/#{qid}/[0-9a-zA-Z]+_foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { modification; quiz.reload }.to change(quiz, :instructions)
      expect(quiz.instructions).to include 's3://xikolo-quiz/quizzes'
    end

    it 'rejects invalid upload and does not update the quiz' do
      stub_request(
        :head,
        'https://s3.xikolo.de/xikolo-uploads/' \
        'uploads/b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg'
      ).and_return(
        status: 200,
        headers: {
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_quiz_instructions',
          'X-Amz-Meta-Xikolo-State' => 'rejected',
        }
      )

      expect { modification }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'instructions' => ['rtfile_rejected']
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
          'X-Amz-Meta-Xikolo-Purpose' => 'quiz_quiz_instructions',
          'X-Amz-Meta-Xikolo-State' => 'accepted',
        }
      )
      store_regex = %r{https://s3.xikolo.de/xikolo-quiz
                       /quizzes/#{qid}/[0-9a-zA-Z]+_foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { modification }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'instructions' => ['rtfile_error']
      end
    end
  end
end
