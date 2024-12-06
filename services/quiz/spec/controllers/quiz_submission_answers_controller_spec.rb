# frozen_string_literal: true

require 'spec_helper'

describe QuizSubmissionAnswersController, type: :controller do
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject(:request) { get :index }

    let!(:answer) { create(:quiz_submission_selectable_answer) }

    it 'answers' do
      request
      expect(response).to have_http_status :ok
    end

    it 'answers with a list' do
      request
      expect(json).to have(1).item
    end

    it 'answers with quiz_submission_selectable_answer objects' do
      request
      expect(json[0]).to eq(QuizSubmissionAnswerDecorator.new(answer).as_json(api_version: 1).stringify_keys)
    end
  end
end
