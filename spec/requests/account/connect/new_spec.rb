# frozen_string_literal: true

require 'spec_helper'

describe 'Account: Connect: New', type: :request do
  subject(:result) { get '/accounts/connect', params:, headers: }

  let(:params) { {} }
  let(:headers) { {} }

  context 'with no authorization' do
    it 'responds with 404 Not Found' do
      expect { result }.to raise_error AbstractController::ActionNotFound
    end
  end

  context 'with an authorization' do
    let(:params) { {authorization: authorization.id} }
    let(:user) { create(:user) }
    let(:authorization) { create(:authorization, user:, provider: 'saml') }

    context 'as an anonymous user' do
      it 'renders the new template' do
        expect(result).to render_template(:new)
        expect(response.body).to include 'Connect account'
      end
    end

    context 'as a logged-in user' do
      let(:headers) { {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"} }

      before { stub_user_request }

      it 'responds with 404 Not Found' do
        expect { result }.to raise_error AbstractController::ActionNotFound
      end
    end
  end
end
