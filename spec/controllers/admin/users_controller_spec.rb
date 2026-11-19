# frozen_string_literal: true

require 'spec_helper'

describe Admin::UsersController, type: :controller do
  subject(:action) { -> { get :index, params: request_params } }

  let(:user) { create(:'account_service/user') }
  let(:permissions) { [] }
  let(:request_params) { {} }

  describe '#index' do
    context 'without permission' do
      before do
        sign_in user:, permissions:
      end

      it 'redirects' do
        action.call
        expect(response).to redirect_to root_url
      end
    end

    context 'with permission' do
      let(:permissions) { ['account.user.index'] }
      let!(:confirmed_user) { create(:'account_service/user') }
      let!(:unconfirmed_user) { create(:'account_service/user', :unconfirmed) }
      let!(:banned_user) { create(:'account_service/user', :banned) }

      before do
        sign_in user:, permissions:
      end

      it 'renders #index' do
        action.call
        expect(response).to render_template(:index)
      end

      context 'when status is banned' do
        let(:request_params) { {status: 'banned'} }

        it 'returns banned users only' do
          action.call
          expect(assigns(:users)).to include(banned_user)
          expect(assigns(:users)).not_to include(confirmed_user, unconfirmed_user)
        end
      end

      context 'when status is confirmed' do
        let(:request_params) { {status: 'confirmed'} }

        it 'returns confirmed users only' do
          action.call
          expect(assigns(:users)).to include(confirmed_user, banned_user)
          expect(assigns(:users)).not_to include(unconfirmed_user)
        end
      end

      context 'when status is unconfirmed' do
        let(:request_params) { {status: 'unconfirmed'} }

        it 'returns unconfirmed users only' do
          action.call
          expect(assigns(:users)).to include(unconfirmed_user)
          expect(assigns(:users)).not_to include(confirmed_user, banned_user)
        end
      end

      context 'when status is top_talent' do
        let(:request_params) { {status: 'top_talent'} }

        let!(:top_talent_user) do
          user = create(:'account_service/user')
          user.grant_top_talent!(source: 'admin')
          user
        end
        let!(:regular_user) { create(:'account_service/user') }

        it 'returns top talent users only' do
          action.call
          expect(assigns(:users)).to include(top_talent_user)
          expect(assigns(:users)).not_to include(regular_user)
        end
      end
    end
  end
end
