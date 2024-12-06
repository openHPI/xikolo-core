# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Multiple Choice Questions: List', type: :request do
  subject(:resource) { api.rel(:multiple_choice_questions).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { {} }

  before { create(:multiple_choice_question) }

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(1).item }
  it { is_expected.to all include('id', 'quiz_id', 'text', 'points', 'shuffle_answers', 'type', 'position') }

  context 'when other question types exist' do
    before { create(:free_text_question) }

    it { is_expected.to have(1).item }

    it 'includes only multiple choice questions' do
      expect(resource.pluck('type')).to all eq('Xikolo::Quiz::MultipleChoiceQuestion')
    end
  end
end
