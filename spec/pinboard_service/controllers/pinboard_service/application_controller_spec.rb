# frozen_string_literal: true

require 'spec_helper'

describe PinboardService::ApplicationController, type: :controller do
  routes { PinboardService::Engine.routes }
  let(:default_params) { {format: 'json'} }
  let(:json) { JSON.parse(response.body) }

  describe '#index' do
    subject { json }

    let(:action) { -> { get :index } }

    before { get :index, params: {}, as: :json }

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

  describe '#error_record_invalid' do
    it 'responds with 422 Unprocessable Entity and full error messages' do
      record = PinboardService::Question.new
      record.errors.add(:base, 'forum_closed')
      exception = ActiveRecord::RecordInvalid.new(record)

      controller = PinboardService::ApplicationController.new
      allow(controller).to receive(:render).and_return(nil) # suppress actual render

      controller.send(:error_record_invalid, exception)

      expect(controller).to have_received(:render).with(
        status: :unprocessable_content,
        json: {errors: ['forum_closed']}
      )
    end
  end
end
