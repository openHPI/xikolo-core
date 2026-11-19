# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviders: Update', type: :request do
  let(:update_video_provider) { patch "/admin/video_providers/#{provider.id}", params: }
  let(:params) { {} }
  let(:provider) { create(:video_provider, :vimeo) }

  context 'for logged-in users' do
    before { sign_in(user:) }

    context 'with permissions' do
      let(:user) { create(:'account_service/user', :admin) }

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
          expect(response).to redirect_to admin_video_providers_path
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
      let(:user) { create(:'account_service/user') }

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
