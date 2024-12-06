# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviders: Update', type: :request do
  let(:update_video_provider) { patch "/video_providers/#{provider.id}", params:, headers: }
  let(:headers) { {} }
  let(:params) { {} }
  let(:provider) { create(:video_provider, :vimeo) }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { ['video.provider.manage'] }

      context 'with valid params for Vimeo' do
        let(:params) do
          {
            video_provider: {name: 'new_name', provider_type: 'vimeo'},
            video_provider_credentials_vimeo: {token: 'new_token'},
          }
        end

        it 'patches the video provider' do
          update_video_provider

          expect(provider.reload.name).to eq 'new_name'
          expect(provider.credentials).to eq({'token' => 'new_token'})
        end

        it 'redirects to the index page' do
          update_video_provider
          expect(response).to redirect_to video_providers_path
        end
      end

      context 'with valid params for Kaltura' do
        let(:provider) { create(:video_provider, :kaltura) }
        let(:params) do
          {
            video_provider: {name: 'new_name', provider_type: 'kaltura'},
            video_provider_credentials_kaltura: {
              partner_id: 'new-partner', token: 'new-token', token_id: 'new-token-id'
            },
          }
        end

        it 'patches the video provider' do
          update_video_provider

          expect(provider.reload.name).to eq 'new_name'
          expect(provider.credentials).to eq({
            'partner_id' => 'new-partner',
            'token' => 'new-token',
            'token_id' => 'new-token-id',
          })
        end

        it 'redirects to the index page' do
          update_video_provider
          expect(response).to redirect_to video_providers_path
        end
      end

      context 'with invalid params' do
        let(:provider_attributes) { {name: ''} }
        let(:params) do
          {
            video_provider: {name: '', provider_type: 'vimeo'},
            video_provider_credentials_vimeo: {token: 'new_token'},
          }
        end

        it 'throws an error' do
          expect { update_video_provider }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

      it 'redirects to the start page' do
        update_video_provider
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the start page' do
      update_video_provider
      expect(response).to redirect_to root_url
    end
  end
end
