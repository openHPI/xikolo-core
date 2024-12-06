# frozen_string_literal: true

require 'spec_helper'

describe ApplicationController, type: :controller do
  let(:default_params) { {format: 'json'} }
  let(:json) { JSON.parse(response.body) }

  describe '#index' do
    subject { get :index; json }

    it { is_expected.to have_key 'quizzes_url' }
    it { is_expected.to have_key 'quiz_url' }
    it { is_expected.to have_key 'questions_url' }
    it { is_expected.to have_key 'question_url' }
    it { is_expected.to have_key 'answers_url' }
    it { is_expected.to have_key 'answer_url' }

    it { is_expected.to have_key 'quiz_submissions_url' }
    it { is_expected.to have_key 'quiz_submission_url' }
    it { is_expected.to have_key 'quiz_submission_questions_url' }
    it { is_expected.to have_key 'user_quiz_attempts_url' }
  end
end
