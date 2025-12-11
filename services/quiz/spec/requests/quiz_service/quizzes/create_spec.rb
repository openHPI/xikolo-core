# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Quiz: Create', type: :request do
  subject(:creation) { api.rel(:quizzes).post(payload).value! }

  let(:api) { Restify.new(quiz_service_url).get.value! }
  let(:payload) { attributes_for(:'quiz_service/quiz') }

  it { is_expected.to respond_with :created }

  it 'creates a new quiz' do
    expect { creation }.to change(QuizService::Quiz, :count).from(0).to(1)
  end

  context 'instructions with file upload references' do
    let(:instructions) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:payload) { super().merge instructions: }

    it 'stores valid upload and creates a new resource' do
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
                       /quizzes/[0-9a-zA-Z]+/[0-9a-zA-Z]+_foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 200, body: '<xml></xml>')
      expect { creation }.to change(QuizService::Quiz, :count).from(0).to(1)
      expect(QuizService::Quiz.last.instructions).to include 's3://xikolo-quiz/quizzes'
    end

    it 'rejects invalid upload and does not creates a new quiz' do
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

      expect { creation }.to raise_error(Restify::ClientError) do |error|
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
                       /quizzes/[0-9a-zA-Z]+/[0-9a-zA-Z]+_foo.jpg}x
      stub_request(:head, store_regex).and_return(status: 404)
      stub_request(:put, store_regex).and_return(status: 503)

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_content
        expect(error.errors).to eq 'instructions' => ['rtfile_error']
      end
    end
  end
end
