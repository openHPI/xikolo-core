# frozen_string_literal: true

require 'spec_helper'

describe QuizService::TextAnswersController, type: :controller do
  include_context 'quiz_service API controller'

  let(:answer) { create(:'quiz_service/text_answer') }
  let(:params) { attributes_for(:'quiz_service/text_answer', type: 'TextAnswer') }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    it 'answers' do
      get :index
      expect(response).to have_http_status :ok
    end

    it 'answers with a list' do
      answer
      get :index
      expect(response).to have_http_status :ok
      expect(json).to have(1).item
    end

    it 'answers with answer objects' do
      answer
      get :index
      expect(response).to have_http_status :ok
      expect(json[0]).to eql QuizService::AnswerDecorator.new(answer).as_json(api_version: 1).stringify_keys
    end
  end

  describe '#show' do
    it 'answers' do
      get :show, params: {id: answer.id}
      expect(response).to have_http_status :ok
    end

    it 'answers with answer object' do
      get :show, params: {id: answer.id}
      expect(json).to eql QuizService::AnswerDecorator.new(answer).as_json(api_version: 1).stringify_keys
    end
  end

  describe '#create' do
    subject(:action) { post :create, params: params.merge(question_id: question.id) }

    let(:question) { create(:'quiz_service/multiple_answer_question') }

    it { is_expected.to be_successful }

    it 'creates an answer' do
      expect { action }.to change(QuizService::Answer, :count).from(0).to(1)
    end

    context 'FreeTextAnswer' do
      let(:free_text_answer) { create(:'quiz_service/free_text_answer') }
      let(:params) { attributes_for(:'quiz_service/answer').merge(correct: false) }

      it 'alwayses be correct' do
        action
        expect(free_text_answer.correct).to be true
      end
    end
  end

  describe '#update' do
    it 'answers' do
      put :update, params: {id: answer.id, quiz_question: params.merge(correct: false)}
      expect(response).to have_http_status :no_content
    end
  end

  describe '#destroy' do
    subject(:request) { delete :destroy, params: {id: answer.id} }

    let!(:answer) { create(:'quiz_service/text_answer', text: 's3://xikolo-quiz/quizzes/1/1/test.jpg') }
    let!(:file_deletion) do
      stub_request(:delete, 'https://s3.xikolo.de/xikolo-quiz/quizzes/1/1/test.jpg')
    end

    it { is_expected.to be_successful }

    it { expect { request }.to change(QuizService::Answer, :count).from(1).to(0) }

    it 'deletes referenced instructions files' do
      request
      expect(file_deletion).to have_been_requested
    end
  end

  describe 'with versioning', :versioning do
    let(:answer1) { create(:'quiz_service/text_answer', correct: true, comment: 'Correct answer, well done!') }
    let(:answer2) { create(:'quiz_service/text_answer', correct: true) }
    let(:answer3) { create(:'quiz_service/text_answer', correct: false) }

    let(:update_comment) { -> { put :update, params: {id: answer1.id, comment: 'Correct, well done!'} } }
    let(:update_correct1) { -> { put :update, params: {id: answer1.id, correct: false} } }
    let(:update_correct2) { -> { put :update, params: {id: answer2.id, correct: false} } }
    let(:update_correct3) { -> { put :update, params: {id: answer3.id, correct: true} } }

    it 'returns one version at the beginning' do
      expect(answer1.versions.size).to be 1
    end

    it 'returns two versions when modified' do
      update_comment.call
      answer1.reload
      expect(answer1.versions.size).to be 2
    end

    it 'answers with the previous version' do
      update_comment.call
      answer1.reload
      expect(answer1.comment).to eq 'Correct, well done!'
      expect(answer1.paper_trail.previous_version.comment).to eq 'Correct answer, well done!'
    end
  end
end
