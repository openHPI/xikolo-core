# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviders: Edit', type: :request do
  let(:edit_video_provider) { get "/admin/video_providers/#{provider.id}/edit" }
  let(:provider) { create(:video_provider, :vimeo) }

  context 'for logged-in users' do
    before { sign_in(user:) }

    context 'with permissions' do
      let(:user) { create(:'account_service/user', :admin) }

      it 'renders the edit page' do
        edit_video_provider
        expect(response).to render_template :edit
      end
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user') }

      it 'redirects to the start page' do
        edit_video_provider
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the start page' do
      edit_video_provider
      expect(response).to redirect_to root_url
    end
  end
end
