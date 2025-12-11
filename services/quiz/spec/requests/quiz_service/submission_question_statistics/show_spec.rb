# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SubmissionQuestionStatistics: Show', type: :request do
  subject(:show) { api.rel(:submission_question_statistic).get(params).value! }

  let(:api) { Restify.new(quiz_service_url).get.value! }
  let(:question) { create(:'quiz_service/multiple_choice_question') }
  let(:params) { {id: question.id} }

  it { is_expected.to respond_with :ok }

  context 'response' do
    it do
      expect(show).to include(
        'id',
        'type',
        'position',
        'max_points',
        'avg_points',
        'submission_count',
        'submission_user_count',
        'correct_submission_count',
        'incorrect_submission_count',
        'partly_correct_submission_count'
      )
    end
  end

  context 'multiple_choice_question' do
    let(:question) { create(:'quiz_service/multiple_choice_question') }

    it { is_expected.to include('answers') }
  end

  context 'multiple_answer_question' do
    let(:question) { create(:'quiz_service/multiple_answer_question') }

    it { is_expected.to include('answers') }
  end

  context 'free_text_question' do
    let(:question) { create(:'quiz_service/free_text_question') }

    it { is_expected.to include('answers') }

    it do
      expect(show['answers']).to include(
        'unique_answer_count',
        'non_unique_answer_texts'
      )
    end
  end

  context 'essay_question' do
    let(:question) { create(:'quiz_service/essay_question') }

    it { is_expected.to include('answers') }
    it { expect(show['answers']).to include('avg_length') }
  end
end
