# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Confirmations: Show', type: :request do
  subject(:resp) do
    get("/account/confirm/#{payload}", headers:)
    response
  end

  let(:verifier) { Account::ConfirmationsController.verifier }
  let(:payload) { verifier.generate(email_id) }
  let(:user_id) { 'c5ef6c12-50bb-4b1a-a20e-40b90e776d79' }
  let(:email_id) { '4a0029ed-ffe8-4ebf-85d7-1b8092fd6890' }
  let(:headers) { {} }

  let(:email_response) { Stub.json({address: 'example@example.org'}) }

  before do
    Stub.request(:account, :get, "/emails/#{email_id}")
      .to_return email_response
  end

  it 'responds with 200 Ok' do
    expect(resp).to have_http_status :ok
  end

  it 'renders show template' do
    expect(resp).to render_template 'account/confirmations/show'
  end

  context 'with not found email resource' do
    let(:email_response) { {status: 404} }

    it 'renders custom confirmation failed template' do
      expect(resp.body).to include('The confirmation period for your account has already ended')
    end

    it 'responds with 404 Not Found' do
      expect(resp).to have_http_status :not_found
    end
  end

  context 'with invalid payload' do
    let(:payload) { 'invalid' }

    it 'responds with 400 Bad Request' do
      expect(resp).to have_http_status :bad_request
    end

    it 'renders custom invalid signature template' do
      expect(resp).to render_template 'account/confirmations/invalid_signature'
    end
  end

  context 'with auto login' do
    before do
      xi_config <<~YML
        auto_login:
          enabled: true
          auth_provider: test
          issuer_domain: example.org
      YML
    end

    let(:headers) { {'X-SSL-Issuer' => 'john@example.org'} }

    it 'responds with 200 Ok' do
      expect(resp).to have_http_status :ok
    end

    it 'renders show template' do
      expect(resp).to render_template 'account/confirmations/show'
    end
  end
end
