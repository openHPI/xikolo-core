# frozen_string_literal: true

require 'spec_helper'

describe ApplicationController, type: :controller do
  let(:default_params) { {format: 'json'} }
  let(:json) { JSON.parse(response.body) }

  describe '#index' do
    subject { json }

    let(:action) { -> { get :index } }

    before { get :index }

    it { is_expected.to have_key 'questions_url' }
    it { is_expected.to have_key 'question_url' }
    it { is_expected.to have_key 'answers_url' }
    it { is_expected.to have_key 'answer_url' }
    it { is_expected.to have_key 'comments_url' }
    it { is_expected.to have_key 'comment_url' }
    it { is_expected.to have_key 'subscriptions_url' }
    it { is_expected.to have_key 'votes_url' }
    it { is_expected.to have_key 'explicit_tags_url' }
    it { is_expected.to have_key 'implicit_tags_url' }
  end
end
