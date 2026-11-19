# frozen_string_literal: true

require 'spec_helper'

describe Admin::VideosController, type: :controller do
  let(:permissions) { [] }
  let(:user) { create(:'account_service/user') }

  describe '#index' do
    subject(:action) { get :index }

    before { sign_in user: user, permissions: }

    context 'with no params' do
      let(:permissions) { super().push('video.video.manage') }

      it 'answers with a page' do
        action
        expect(response).to have_http_status :ok
      end
    end

    context 'as user' do
      it 'redirects to the start page' do
        action
        expect(response).to redirect_to '/'
      end
    end
  end
end
