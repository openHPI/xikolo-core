# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Videos: Destroy', type: :request do
  let(:destroy_video) { delete "/videos/#{stream.id}" }
  let!(:stream) { create(:stream) }

  context 'for logged-in users' do
    before { sign_in(user:) }

    context 'with permissions' do
      let(:user) { create(:'account_service/user', :admin) }

      it 'deletes the stream' do
        expect { destroy_video }.to change(Video::Stream, :count).from(1).to(0)
      end

      it 'redirects to the index page' do
        destroy_video
        expect(response).to redirect_to videos_path
      end

      context 'with referenced stream' do
        before { create(:video, pip_stream: stream) }

        it 'does not delete the stream' do
          expect { destroy_video }.not_to change(Video::Stream, :count)
        end

        it 'shows an error message' do
          destroy_video
          expect(request.flash[:error].first).to eq('The video stream could not be deleted as it is still used in learning units.')
        end
      end
    end

    context 'without permissions' do
      let(:user) { create(:'account_service/user') }

      it 'redirects to the start page' do
        destroy_video
        expect(response).to redirect_to root_url
      end
    end
  end

  context 'for anonymous users' do
    it 'redirects to the start page' do
      destroy_video
      expect(response).to redirect_to root_url
    end
  end
end
