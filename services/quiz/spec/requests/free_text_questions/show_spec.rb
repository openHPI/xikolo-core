# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Free Text Questions: Show', type: :request do
  subject { api.rel(:free_text_question).get({id: question.id}).value! }

  let(:api) { Restify.new(:test).get.value! }

  let!(:question) { create(:free_text_question) }

  it { is_expected.to respond_with :ok }

  context 'response' do
    it { is_expected.to include('id', 'quiz_id', 'text', 'points', 'shuffle_answers', 'type', 'position') }
  end
end
