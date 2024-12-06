# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Answers: Create', type: :request do
  subject(:creation) { api.rel(:answers).post(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { attributes_for(:answer).merge question_id: question.id }
  let(:quiz) { create(:quiz) }
  let(:question) { create(:multiple_choice_question, quiz:) }
  let(:qid) { UUID4(quiz.id).to_s(format: :base62) }

  it { is_expected.to respond_with :created }

  it 'creates a new answer' do
    expect { creation }.to change(Answer, :count).from(0).to(1)
    expect(Answer.last.question).not_to be_nil
  end

  context 'text with file upload references' do
    let(:text) { 'upload://b5f99337-224f-40f5-aa82-44ee8b272579/foo.jpg' }
    let(:params) { super().merge text: }

    it 'stores valid upload and creates a new resource' do
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
      expect { creation }.to change(Answer, :count).from(0).to(1)
      expect(Answer.last.text).to include 's3://xikolo-quiz/quizzes'
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

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
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

      expect { creation }.to raise_error(Restify::ClientError) do |error|
        expect(error.status).to eq :unprocessable_entity
        expect(error.errors).to eq 'text' => ['rtfile_error']
      end
    end
  end
end
