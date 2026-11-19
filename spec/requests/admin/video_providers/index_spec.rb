# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviders: Index', type: :request do
  subject(:get_video_providers) { get '/admin/video_providers' }

  context 'for logged-in users' do
    before { sign_in(user:) }

    context 'with permissions' do
      let(:user) { create(:'account_service/user', :admin) }

      it 'renders the index page' do
        get_video_providers
        expect(response).to render_template :index
      end
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user') }

      it 'redirects to the start page' do
        get_video_providers
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the start page' do
      get_video_providers
      expect(response).to redirect_to root_url
    end
  end
end
