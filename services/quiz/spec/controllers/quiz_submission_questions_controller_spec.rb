# frozen_string_literal: true

require 'spec_helper'

describe QuizSubmissionQuestionsController, type: :controller do
  let!(:question) { create(:quiz_submission_question) }
  let(:json) { JSON.parse response.body }
  let(:default_params) { {format: 'json'} }

  describe '#index' do
    subject(:request) { get :index }

    it 'answers' do
      request
      expect(response).to have_http_status :ok
    end

    it 'answers with a list' do
      request
      expect(json).to have(1).item
    end

    it 'answers with quiz_submission_question objects' do
      request
      expect(json[0]).to eq(QuizSubmissionQuestionDecorator.new(question).as_json(api_version: 1).stringify_keys)
    end
  end
end
