# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::V2::TokenAPI, type: :request do
  describe 'POST authenticate' do
    subject do
      post '/api/v2/authenticate',
        params:,
        headers: {
          'Accept' => 'application/json',
        }
    end

    before do
      Stub.service(:account, build(:'account:root'))

      # Requests for a new session will fail (credentials invalid) by default
      Stub.request(
        :account, :post, '/sessions'
      ).to_return Stub.json({}, status: 422)

      # With valid credentials, we can create a new session object
      Stub.request(
        :account, :post, '/sessions',
        body: {ident: 'valid@xikolo.de', password: 'valid_password'}
      ).to_return Stub.json({
        tokens_url: '/account_service/tokens_for_session',
      })

      # For valid requests, we can also retrieve a token
      Stub.request(
        :account, :post, '/tokens_for_session'
      ).to_return Stub.json({
        token: 'abcde',
        user_id: '12345',
      })
    end

    context 'with credentials' do
      let(:params) { {email:, password:} }

      context 'valid email and password' do
        let(:email) { 'valid@xikolo.de' }
        let(:password) { 'valid_password' }

        describe '(response)' do
          subject { super(); response }

          it { is_expected.to have_http_status :created }
        end

        describe '(json)' do
          subject { super(); JSON.parse response.body }

          it { is_expected.to eq('token' => 'abcde', 'user_id' => '12345') }
        end
      end

      context 'invalid email and password' do
        let(:email) { 'invalid@xikolo.de' }
        let(:password) { 'wrong_password' }

        describe '(response)' do
          subject { super(); response }

          it { is_expected.to have_http_status :unauthorized }
        end
      end
    end

    context 'without credentials' do
      let(:params) { {} }

      describe '(response)' do
        subject { super(); response }

        it { is_expected.to have_http_status :bad_request }
      end
    end
  end
end
