# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Confirmations: Create', type: :request do
  subject(:resp) do
    post('/account/confirm/', params:, headers:)
    response
  end

  let(:verifier) { Account::ConfirmationsController.verifier }
  let(:params)   { {request: verifier.generate('john@example.org')} }
  let(:headers)  { {} }

  before do
    Stub.request(:account, :get, '/emails/john@example.org')
      .to_return Stub.json({
        id: '45709320-66c3-4732-b786-1f562a882b77',
        user_id: '8fc575b8-d881-4024-b787-ae010dd2f81b',
      })
  end

  it 'redirects to login' do
    expect(resp).to redirect_to '/sessions/new'
  end

  it 'enqueues confirm email job' do
    expect(NotificationService::SendConfirmEmailJob)
      .to receive(:perform_later) do |event|
        expect(event).to match(
          id: '45709320-66c3-4732-b786-1f562a882b77',
          user_id: '8fc575b8-d881-4024-b787-ae010dd2f81b',
          url: match(%r{/account/confirm/[^/]+$})
        )

        event[:url].split('/').last.tap do |payload|
          expect(verifier.verified(payload)).to eq(
            '45709320-66c3-4732-b786-1f562a882b77'
          )
        end
      end

    resp
  end

  context 'with invalid signature' do
    let(:params) { {request: 'invalid'} }

    it 'responds with 400 Bad Request' do
      expect(resp).to have_http_status :bad_request
    end

    it 'renders custom invalid signature template' do
      expect(resp).to render_template 'account/confirmations/invalid_signature'
    end
  end
end
