# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Treatments: Consent', type: :request do
  subject(:consent) { post '/treatments', params:, headers: }

  let!(:user) { stub_user_request }
  let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }
  let!(:patch_consents) do
    Stub.request(:account, :patch, '/myconsents')
      .to_return Stub.response(status: 204)
  end

  before do
    Stub.request(:account, :get, "/users/#{user[:id]}")
      .to_return Stub.json({consents_url: '/account_service/myconsents'})
  end

  context 'to all treatments' do
    let(:params) do
      {
        treatments: 'data_processing,tracking',
        consent: %w[data_processing tracking],
      }
    end

    it 'submits all consents correctly' do
      consent

      expect(
        patch_consents.with(body: [
          {name: 'data_processing', consented: true},
          {name: 'tracking', consented: true},
        ].to_json)
      ).to have_been_requested.once
    end
  end

  context 'to some treatments' do
    let(:params) do
      {
        treatments: 'data_processing,tracking',
        consent: %w[data_processing],
      }
    end

    it 'submits all consents correctly' do
      consent

      expect(
        patch_consents.with(body: [
          {name: 'data_processing', consented: true},
          {name: 'tracking', consented: false},
        ].to_json)
      ).to have_been_requested.once
    end
  end

  context 'to none of the treatments' do
    let(:params) do
      {
        treatments: 'data_processing,tracking',
        consent: nil,
      }
    end

    it 'submits all consents correctly' do
      consent

      expect(
        patch_consents.with(body: [
          {name: 'data_processing', consented: false},
          {name: 'tracking', consented: false},
        ].to_json)
      ).to have_been_requested.once
    end
  end
end
