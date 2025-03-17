# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviders: Index', type: :request do
  subject(:get_video_providers) { get '/admin/video_providers', headers: }

  let(:headers) { {} }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { ['video.provider.manage'] }

      it 'renders the index page' do
        get_video_providers
        expect(response).to render_template :index
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

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
