# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviders: Create', type: :request do
  let(:create_video_provider) { post '/admin/video_providers', params:, headers: }
  let(:headers) { {} }
  let(:params) { {} }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { ['video.provider.manage'] }

      context 'with valid params for Vimeo' do
        let(:params) do
          {
            video_provider: {name: 'the_name', provider_type: 'vimeo'},
            video_provider_credentials_vimeo: {token: 'the_token'},
          }
        end

        it 'creates the video provider' do
          expect { create_video_provider }.to change(Video::Provider, :count).from(0).to(1)

          created_provider = Video::Provider.first
          expect(created_provider.provider_type).to eq 'vimeo'
          expect(created_provider.name).to eq 'the_name'
          expect(created_provider.credentials).to eq({'token' => 'the_token'})
        end

        it 'redirects to the index page' do
          create_video_provider
          expect(response).to redirect_to admin_video_providers_path
        end
      end

      context 'with valid params for Kaltura' do
        let(:params) do
          {
            video_provider: {name: 'the_name', provider_type: 'kaltura'},
            video_provider_credentials_kaltura: {
              partner_id: 'the-partner', token: 'the-token', token_id: 'the-token-id'
            },
          }
        end

        it 'creates the video provider' do
          expect { create_video_provider }.to change(Video::Provider, :count).from(0).to(1)

          created_provider = Video::Provider.first
          expect(created_provider.provider_type).to eq 'kaltura'
          expect(created_provider.name).to eq 'the_name'
          expect(created_provider.credentials).to eq({
            'partner_id' => 'the-partner',
            'token' => 'the-token',
            'token_id' => 'the-token-id',
          })
        end

        it 'redirects to the index page' do
          create_video_provider
          expect(response).to redirect_to admin_video_providers_path
        end
      end

      context 'with invalid params' do
        let(:params) do
          {
            video_provider: {name: '', provider_type: 'vimeo'},
            video_provider_credentials_vimeo: {token: 'the_token'},
          }
        end

        it 're-renders the creation form' do
          create_video_provider
          expect(response).to render_template :new
        end
      end
    end

    context 'without permissions' do
      let(:permissions) { [] }

      it 'redirects to the start page' do
        create_video_provider
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the start page' do
      create_video_provider
      expect(response).to redirect_to root_url
    end
  end
end
