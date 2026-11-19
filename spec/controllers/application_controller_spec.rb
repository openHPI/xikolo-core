# frozen_string_literal: true

require 'spec_helper'

describe ApplicationController, type: :controller do
  controller do
    def index
      head :ok
    end
  end

  describe '#current_session' do
    context 'when a user is signed in' do
      let(:session_record) { create(:'account_service/session') }

      before do
        allow(AccountService::Session).to receive(:find_by).and_return(session_record)
        sign_in user: session_record.user
      end

      it 'calls .access! on the session to record activity' do
        expect(session_record).to receive(:access!)
        get :index

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when no user is signed in' do
      it 'does not call .access! with no session id' do
        session[:id] = nil
        expect(AccountService::Session).not_to receive(:find_by)
        get :index

        expect(response).to have_http_status(:ok)
      end

      it 'does not call .access! with anonymous session id' do
        session[:id] = 'anonymous'
        expect(AccountService::Session).not_to receive(:find_by)
        get :index

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
