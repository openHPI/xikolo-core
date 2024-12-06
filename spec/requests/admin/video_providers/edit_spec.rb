# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviders: Edit', type: :request do
  let(:edit_video_provider) { get "/video_providers/#{provider.id}/edit", headers: }
  let(:headers) { {} }
  let(:provider) { create(:video_provider, :vimeo) }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { ['video.provider.manage'] }

      it 'renders the edit page' do
        edit_video_provider
        expect(response).to render_template :edit
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

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
