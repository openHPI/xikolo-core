# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Confirmations: Update', type: :request do
  subject(:resp) do
    put("/account/confirm/#{payload}", headers:)
    response
  end

  let(:verifier) { Account::ConfirmationsController.verifier }
  let(:payload) { verifier.generate(email_id) }
  let(:user_id) { 'c5ef6c12-50bb-4b1a-a20e-40b90e776d79' }
  let(:email_id) { '4a0029ed-ffe8-4ebf-85d7-1b8092fd6890' }
  let(:headers) { {} }

  let(:email) do
    {
      id: email_id,
      user_id:,
      confirmed: false,
      self_url: "/account_service/users/#{user_id}/emails/#{email_id}",
    }
  end

  let!(:confirm) do
    Stub.request(:account, :patch, "/users/#{user_id}/emails/#{email_id}")
      .with(body: hash_including('confirmed' => true))
      .to_return Stub.json({user_id:})
  end

  before do
    Stub.request(:news, :get, '/news')
      .with(query: hash_including({}))
      .to_return Stub.json([])

    Stub.request(:account, :get, "/emails/#{email_id}")
      .to_return Stub.json(email)
  end

  it 'confirms the email address' do
    expect(resp).to redirect_to '/sessions/new'
    expect(confirm).to have_been_requested.once
  end

  context 'with invalid signature' do
    let(:payload) { super()[0..-2] }

    it 'responds with 400 Bad Request' do
      expect(resp).to have_http_status :bad_request
    end

    it 'renders custom invalid signature template' do
      expect(resp).to render_template 'account/confirmations/invalid_signature'
    end
  end

  context 'with already confirmed email address' do
    let(:email) { super().merge(confirmed: true) }

    it 'responds with 410 Gone' do
      expect(resp).to have_http_status :gone
    end

    it { is_expected.to render_template 'account/confirmations/confirmed_token' }
  end
end
