# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Confirmations: New', type: :request do
  subject(:resp) do
    get('/account/confirm/new', params:, headers:)
    response
  end

  let(:verifier) { Account::ConfirmationsController.verifier }
  let(:params) { {request: verifier.generate('example@example.org')} }
  let(:headers) { {} }

  it 'responds with 200 Ok' do
    expect(resp).to have_http_status :ok
  end

  it 'renders new template' do
    expect(resp).to render_template 'account/confirmations/new'
  end

  context 'with invalid payload' do
    let(:params) { {request: 'invalid'} }

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
      expect(resp).to render_template 'account/confirmations/new'
    end
  end
end
