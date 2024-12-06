# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: VideoProviderSync: Create', type: :request do
  let(:create_provider_sync) do
    post "/video_providers/#{provider.id}/sync", params:, headers:
  end
  let(:headers) { {} }
  let(:params) { {id: provider.id} }
  let(:provider) { create(:video_provider, :vimeo) }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request(permissions:) }

    context 'with permissions' do
      let(:permissions) { ['video.video.manage'] }

      context 'when triggering a partial sync' do
        let(:params) { super().merge(full: false) }

        it 'triggers the synchronisation' do
          expect { create_provider_sync }.to have_enqueued_job(Video::SyncVideosJob).with(provider: provider.id, full: false)
          expect(flash[:success].first).to eq 'The synchronization has been initiated.'
          expect(response).to redirect_to '/video_providers'
        end

        context 'with a provider sync already running' do
          let(:provider) do
            create(:video_provider, :kaltura, run_at: 2.minutes.ago, synchronized_at: 1.hour.ago)
          end

          it 'does not trigger the synchronisation' do
            expect { create_provider_sync }.not_to have_enqueued_job(Video::SyncVideosJob)
            expect(flash[:notice].first).to eq 'The sync has been recently triggered.'
            expect(response).to redirect_to '/video_providers'
          end
        end

        context 'with a recently triggered sync' do
          let(:provider) do
            sync_time = 50.minutes.ago
            create(:video_provider, :kaltura, run_at: sync_time, synchronized_at: sync_time)
          end

          it 'triggers the synchronisation' do
            expect { create_provider_sync }.to have_enqueued_job(Video::SyncVideosJob).with(provider: provider.id, full: false)
            expect(flash[:success].first).to eq 'The synchronization has been initiated.'
            expect(response).to redirect_to '/video_providers'
          end
        end
      end

      context 'when triggering a full sync' do
        let(:params) { super().merge(full: true) }

        it 'triggers the synchronisation' do
          expect { create_provider_sync }.to have_enqueued_job(Video::SyncVideosJob).with(provider: provider.id, full: true)
          expect(flash[:success].first).to eq 'The synchronization has been initiated.'
          expect(response).to redirect_to '/video_providers'
        end

        context 'with a provider sync running' do
          let(:provider) do
            create(:video_provider, :kaltura, run_at: 2.minutes.ago, synchronized_at: 1.hour.ago)
          end

          it 'does not trigger the synchronisation' do
            expect { create_provider_sync }.not_to have_enqueued_job(Video::SyncVideosJob)
            expect(flash[:notice].first).to eq 'The sync has been recently triggered.'
            expect(response).to redirect_to '/video_providers'
          end
        end

        context 'with a recently triggered sync' do
          let(:provider) do
            sync_time = 50.minutes.ago
            create(:video_provider, :kaltura, run_at: sync_time, synchronized_at: sync_time)
          end

          it 'does not trigger the synchronisation' do
            expect { create_provider_sync }.not_to have_enqueued_job(Video::SyncVideosJob)
            expect(flash[:notice].first).to eq 'The sync has been recently triggered.'
            expect(response).to redirect_to '/video_providers'
          end
        end
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the start page' do
      create_provider_sync
      expect(response).to redirect_to root_url
    end
  end
end
