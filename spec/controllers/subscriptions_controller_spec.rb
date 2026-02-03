# frozen_string_literal: true

require 'spec_helper'

describe SubscriptionsController, type: :controller do
  let!(:question_id) { '00000002-3500-4444-9999-000000000001' }
  let!(:question_id_2) { '00000002-3500-4444-9999-000000000002' }
  let!(:subscription_id) { '00000005-3500-4444-9999-000000000001' }
  let!(:user_id) { '00000001-3100-4444-9999-000000000001' }

  let(:subscription_create_stub) do
    Stub.request(
      :pinboard, :post, '/subscriptions',
      body: hash_including(user_id:, question_id:)
    ).to_return Stub.json({
      id: subscription_id,
      user_id:,
      question_id:,
    })
  end
  let(:subscription_delete_stub) do
    Stub.request(
      :pinboard, :delete, "/subscriptions/#{subscription_id}"
    ).to_return Stub.response(status: 204)
  end

  before do
    stub_user id: user_id, language: 'en'

    Stub.request(
      :pinboard, :get, '/subscriptions',
      query: {user_id:, question_id:}
    ).to_return Stub.json([])
    Stub.request(
      :pinboard, :get, '/subscriptions',
      query: {user_id:, question_id: question_id_2}
    ).to_return Stub.json([
      {id: subscription_id, user_id:, question_id: question_id_2},
    ])

    subscription_create_stub
    subscription_delete_stub
  end

  describe "POST 'toggle_subscription'" do
    it 'creates a subscription if there is none' do
      get 'toggle_subscription', params: {question_id:}
      expect(subscription_create_stub).to have_been_requested
    end

    it 'deletes the subscription if there is one' do
      get 'toggle_subscription', params: {question_id: question_id_2}
      expect(subscription_delete_stub).to have_been_requested
    end
  end
end
