# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Questions: List', type: :request do
  subject(:resource) { api.rel(:questions).get(params).value! }

  let(:api) { Restify.new(:test).get.value! }
  let(:params) { {} }

  before do
    create(:multiple_choice_question)
    create(:multiple_choice_question, exclude_from_recap: true)
  end

  it { is_expected.to respond_with :ok }
  it { is_expected.to have(2).items }
  it { is_expected.to all include('id', 'quiz_id', 'text', 'text', 'explanation', 'points', 'shuffle_answers', 'type', 'position') }

  context 'when multiple different question types exist' do
    before do
      create(:free_text_question)
      create(:essay_question)
    end

    it 'lists all of them' do
      expect(resource).to have(4).items
    end
  end
end
