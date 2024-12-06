# frozen_string_literal: true

require 'spec_helper'

describe FreeTextAnswersController, type: :controller do
  let(:answer) { create(:free_text_answer) }
  let(:params) { attributes_for(:free_text_answer) }
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
      expect(json[0]).to eql AnswerDecorator.new(answer).as_json(api_version: 1).stringify_keys
    end
  end

  describe '#show' do
    it 'answers' do
      get :show, params: {id: answer.id}
      expect(response).to have_http_status :ok
    end

    it 'answers with answer object' do
      get :show, params: {id: answer.id}
      expect(json).to eql AnswerDecorator.new(answer).as_json(api_version: 1).stringify_keys
    end
  end

  describe '#create' do
    subject(:action) { post :create, params: params.merge(question_id: question.id) }

    let(:question) { create(:free_text_question) }

    it { is_expected.to be_successful }

    it 'creates an answer' do
      expect { action }.to change(Answer, :count).from(0).to(1)
    end

    context 'FreeTextAnswer' do
      let(:free_text_answer) { create(:free_text_answer) }
      let(:params) { attributes_for(:answer).merge(correct: false, question_id: question.id) }

      it 'is always correct' do
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

    let!(:answer) { create(:free_text_answer, text: 's3://xikolo-quiz/quizzes/1/1/test.jpg') }
    let!(:file_deletion) do
      stub_request(:delete, 'https://s3.xikolo.de/xikolo-quiz/quizzes/1/1/test.jpg')
    end

    it { is_expected.to be_successful }

    it { expect { request }.to change(Answer, :count).from(1).to(0) }

    it 'deletes referenced instructions files' do
      request
      expect(file_deletion).to have_been_requested
    end
  end

  describe 'with versioning', :versioning do
    let(:answer1) { create(:free_text_answer, correct: true, comment: 'Correct answer, well done!') }
    let(:answer2) { create(:free_text_answer, correct: true) }
    let(:answer3) { create(:free_text_answer, correct: false) }

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
