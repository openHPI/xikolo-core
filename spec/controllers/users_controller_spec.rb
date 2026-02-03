# frozen_string_literal: true

require 'spec_helper'

describe UsersController, type: :controller do
  let!(:user_id) { '00000001-3100-4444-9999-000000000003' }

  before do
    Stub.request(:account, :get, "/users/#{user_id}")
      .to_return Stub.json({id: user_id})
  end

  describe '#show' do
    subject(:show_action) { get :show, params: {id: user_id} }

    before do
      Stub.request(:course, :get, "/teachers?user_id=#{user_id}")
        .to_return Stub.json({})
    end

    context 'as current user' do
      before { stub_user id: user_id }

      it { expect(show_action.status).to eq 200 }
    end
  end

  describe '#destroy' do
    subject(:destroy_action) { delete :destroy, params: {id: user_id} }

    before do
      Stub.request(:account, :delete, "/sessions/#{stub_session_id}")
        .to_return status: 200, headers: {}
      Stub.request(:account, :delete, "/users/#{user_id}")
        .to_return status: 200, headers: {}
    end

    let!(:delete_session) do
      Stub.request(:account, :delete, "/sessions/#{stub_session_id}")
        .to_return status: 200, headers: {}
    end

    context 'as current_user' do
      before { stub_user id: user_id }

      it { is_expected.to redirect_to root_url }

      it 'resets the session' do
        expect { destroy_action }
          .to change { session['id'] }
          .from(stub_session_id)
          .to('anonymous')
      end

      it 'asks xi-account to delete the session' do
        destroy_action

        expect(delete_session).to have_been_requested
      end
    end
  end
end
