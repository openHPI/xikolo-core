# frozen_string_literal: true

require 'spec_helper'

describe Admin::UsersController, type: :controller do
  let(:user_id) { SecureRandom.uuid }
  let(:permissions) { ['account.user.create'] }

  before do
    Stub.service(:account, build(:'account:root'))

    stub_user id: user_id, permissions:
  end

  describe '#index' do
    subject(:action) { -> { get :index } }

    context 'without permission' do
      let(:permissions) { [] }

      it 'redirects' do
        action.call
        expect(response).to redirect_to root_url
      end
    end

    context 'with permission' do
      let(:permissions) { ['account.user.index'] }

      before do
        Stub.request(
          :account, :get, '/users',
          query: {page: '1'}
        ).to_return Stub.json([])
      end

      it 'renders #index' do
        action.call
        expect(response).to render_template(:index)
      end
    end
  end

  describe '#new' do
    subject(:action) { -> { get :new } }

    context 'without permission' do
      let(:permissions) { [] }

      it 'redirects' do
        action.call
        expect(response).to redirect_to root_url
      end
    end

    context 'with permission' do
      let(:permissions) { ['account.user.create'] }

      it 'renders users form' do
        action.call
        expect(response).to render_template(:new)
      end
    end
  end

  describe '#create' do
    subject(:action) { -> { post :create, params: } }

    let(:user_params) do
      {
        full_name: 'Jane Doe',
        email: 'doe@example.de',
        password: 'x',
        password_confirmation: 'x',
        confirmed: 'true',
      }
    end
    let(:params) { {user: user_params} }

    context 'without permission' do
      let(:permissions) { [] }

      it 'redirects' do
        action.call
        expect(response).to redirect_to root_url
      end
    end

    context 'with permission' do
      let(:permissions) { ['account.user.create'] }

      context 'with valid params' do
        let(:user_id) { SecureRandom.uuid }

        before do
          Stub.request(
            :account, :post, '/users/',
            body: anything
          ).to_return Stub.json({id: user_id})
        end

        it 'redirects to user#show' do
          action.call
          expect(response).to redirect_to user_path(user_id)
        end
      end
    end
  end
end
