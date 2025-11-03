# frozen_string_literal: true

require 'spec_helper'

describe AccountService::API::TokensController, type: :controller do
  include_context 'account_service API controller'
  let(:user)   { create(:'account_service/user', password: 'secret123') }
  let(:token)  do
    create(:'account_service/token', user:)
  end
  let(:params) { {} }

  describe '#create' do
    subject(:response) { post :create, params: }

    let(:params) { {user_id: user.id} }

    it { is_expected.to have_http_status :created }

    it 'creates a new token record' do
      expect { response }.to change(AccountService::Token, :count).from(0).to(1)
    end

    context 'with existing record' do
      before do
        create(:'account_service/token', user:)
      end

      it 'does not create an additional token' do
        expect { response }.not_to change(AccountService::Token, :count).from(1)
      end

      it { is_expected.to have_http_status :created }
    end
  end

  describe '#index' do
    subject(:response) { get :index, params: }

    let(:params) { {token: token.token} }

    it { is_expected.to have_http_status :ok }

    describe 'payload' do
      subject(:payload) { JSON.parse(response.body) }

      it 'includes existing token' do
        expect(payload).to eq [
          'id' => token.id,
          'token' => token.token,
          'user_id' => token.user_id,
        ]
      end
    end
  end

  describe '#show' do
    subject(:response) { get :show, params: }

    let(:params) { {id: token.id} }

    it { is_expected.to have_http_status :ok }

    describe 'payload' do
      subject(:payload) { JSON.parse(response.body) }

      it 'includes existing token' do
        expect(payload).to eq \
          'id' => token.id,
          'token' => token.token,
          'user_id' => token.user_id
      end
    end
  end
end
