# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Questions: List', type: :request do
  subject(:resource) { api.rel(:questions).get(params).value! }

  let(:api) { restify_with_headers(quiz_service_url).get.value! }
  let(:params) { {} }

  before do
    create(:'quiz_service/multiple_choice_question')
    create(:'quiz_service/multiple_choice_question', exclude_from_recap: true)
  end

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(2).items }
  it { is_expected.to all include('id', 'quiz_id', 'text', 'text', 'explanation', 'points', 'shuffle_answers', 'type', 'position') }

  context 'when multiple different question types exist' do
    before do
      create(:'quiz_service/free_text_question')
      create(:'quiz_service/essay_question')
    end

    it 'lists all of them' do
      expect(resource).to have(4).items
    end
  end

  context 'for an exam submission' do
    let(:quiz) { create(:'quiz_service/quiz') }
    let!(:selected_question) { create(:'quiz_service/multiple_choice_question', quiz:) }
    let!(:submission) { create(:'quiz_service/quiz_submission', quiz:) }
    let(:params) { {quiz_submission_id: submission.id} }

    before do
      create(:'quiz_service/quiz_submission_question', quiz_submission: submission, quiz_question_id: selected_question.id)
    end

    it 'returns only the persisted question set in its persisted order' do
      expect(resource.pluck('id')).to eq([selected_question.id])
    end
  end
end
