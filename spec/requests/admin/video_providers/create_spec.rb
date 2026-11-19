# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviders: Create', type: :request do
  let(:create_video_provider) { post '/admin/video_providers', params:, headers: }
  let(:headers) { {} }
  let(:params) { {} }

  context 'for logged-in users' do
    before do
      sign_in(user:)
    end

    context 'with permissions' do
      let(:user) { create(:'account_service/user', :admin) }

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

      context 'with valid params for Bunny' do
        let(:params) do
          {
            video_provider: {name: 'the_name', provider_type: 'bunny'},
          }
        end

        it 'creates the video provider' do
          expect { create_video_provider }.to change(Video::Provider, :count).from(0).to(1)

          created_provider = Video::Provider.first
          expect(created_provider.provider_type).to eq 'bunny'
          expect(created_provider.name).to eq 'the_name'
          expect(created_provider.credentials).to eq({})
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
      let(:user) { create(:'account_service/user') }

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
