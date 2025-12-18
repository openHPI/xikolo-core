# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multiple Answer Questions: List', type: :request do
  subject(:resource) { api.rel(:multiple_answer_questions).get(params).value! }

  let(:api) { restify_with_headers(quiz_service_url).get.value! }
  let(:params) { {} }

  before { create(:'quiz_service/multiple_answer_question') }

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(1).item }
  it { is_expected.to all include('id', 'quiz_id', 'text', 'points', 'shuffle_answers', 'type', 'position') }

  context 'when other question types exist' do
    before { create(:'quiz_service/free_text_question') }

    it { is_expected.to have(1).item }

    it 'includes only multiple answer questions' do
      expect(resource.pluck('type')).to all eq('Xikolo::Quiz::MultipleAnswerQuestion')
    end
  end
end
