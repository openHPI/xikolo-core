# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Videos: Retry', type: :request do
  subject(:retry_video) { post "/videos/#{stream.id}/retry" }

  context 'for logged-in users' do
    before { sign_in(user:) }

    context 'with permissions' do
      let(:user) { create(:'account_service/user', :admin) }

      context 'with a failed Bunny stream' do
        let(:stream) do
          create(:stream, :bunny, :with_video,
            provider_video_id: nil, hd_url: nil, sd_url: nil, hls_url: nil,
            upload_state: 'failed', upload_error: 'Bunny is down')
        end

        it 'resets the stream to waiting' do
          expect { retry_video }
            .to change { stream.reload.upload_state }.from('failed').to('waiting')
        end

        it 'clears the upload error' do
          expect { retry_video }.to change { stream.reload.upload_error }.from('Bunny is down').to(nil)
        end

        it 'enqueues the upload job' do
          expect { retry_video }
            .to have_enqueued_job(UploadStreamToBunnyJob).with(stream.id)
        end

        it 'redirects to the index page' do
          retry_video
          expect(response).to redirect_to videos_path
        end
      end

      context 'with a stream that is not failed' do
        let(:stream) { create(:stream, :bunny, :with_video) }

        it 'does not change the upload state' do
          expect { retry_video }.not_to change { stream.reload.upload_state }
        end

        it 'does not enqueue the upload job' do
          expect { retry_video }.not_to have_enqueued_job(UploadStreamToBunnyJob)
        end
      end
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user') }
      let(:stream) { create(:stream, :bunny, :with_video, upload_state: 'failed') }

      it 'redirects to the start page' do
        retry_video
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    let(:stream) { create(:stream, :bunny, :with_video, upload_state: 'failed') }

    it 'redirects to the start page' do
      retry_video
      expect(response).to redirect_to root_url
    end
  end
end
