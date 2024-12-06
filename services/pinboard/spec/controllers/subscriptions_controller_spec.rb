# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionsController, type: :controller do
  let!(:subscription) { create(:subscription) }
  let(:json) { JSON.parse response.body }
  let!(:params) { attributes_for(:subscription) }
  let(:default_params) { {format: 'json'} }
  let(:question) { create(:question) }

  describe '#index' do
    let(:action) { get :index, params: }

    it 'returns subscriptions' do
      get :index
      expect(response).to have_http_status :ok
      expect(json).not_to be_empty
      expect(json.size).to eq(1)
    end

    it 'returns question' do
      get :index, params: {with_question: true}
      expect(response).to have_http_status :ok
    end
  end

  describe '#show' do
    let(:action) { -> { get :show, params: {id: subscription.id} } }

    before { action.call }

    context 'response' do
      subject { response }

      its(:status) { is_expected.to eq 200 }
    end
  end

  describe '#create' do
    it 'creates a new subscription' do
      expect do
        post :create, params: {
          user_id: 'b2147ab3-424b-4777-bb31-976b99cb016f',
          question_id: question.id,
        }

        expect(response).to have_http_status :created
      end.to change(Subscription, :count).from(1).to(2)
    end
  end

  describe '#update' do
    it 'responds with 204 No Content' do
      patch :update, params: params.merge(
        id: subscription.id,
        question_id: question.id
      )

      expect(response).to have_http_status :no_content
    end
  end

  describe '#destroy' do
    it 'deletes subscription' do
      expect do
        delete :destroy, params: {id: subscription.id}
      end.to change(Subscription, :count).from(1).to(0)
    end
  end
end
