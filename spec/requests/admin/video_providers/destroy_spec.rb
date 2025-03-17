# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviders: Destroy', type: :request do
  let(:destroy_video_provider) { delete "/admin/video_providers/#{provider.id}", headers: }
  let(:headers) { {} }
  let!(:provider) { create(:video_provider, :vimeo) }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { ['video.provider.manage'] }

      it 'deletes the video provider' do
        expect { destroy_video_provider }.to change(Video::Provider, :count).from(1).to(0)
        expect(flash[:success].first).to eq('The video provider has been deleted.')
        expect(response).to redirect_to admin_video_providers_path
      end

      context 'with referenced video streams' do
        before do
          stream = create(:stream, provider:)
          create(:video, pip_stream: stream)
        end

        it 'does not allow to delete the video provider' do
          expect { destroy_video_provider }.not_to change(Video::Provider, :count).from(1)
          expect(flash[:error].first).to eq('The video provider could not be deleted as corresponding streams are still referenced.')
          expect(response).to redirect_to admin_video_providers_path
        end
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

      it 'redirects to the start page' do
        destroy_video_provider
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the start page' do
      destroy_video_provider
      expect(response).to redirect_to root_url
    end
  end
end
