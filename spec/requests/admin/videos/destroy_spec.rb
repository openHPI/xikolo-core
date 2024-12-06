# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Videos: Destroy', type: :request do
  let(:destroy_video) { delete "/videos/#{stream.id}", headers: }
  let(:headers) { {} }
  let!(:stream) { create(:stream) }

  context 'for logged-in users' do
    let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }

    before { stub_user_request permissions: }

    context 'with permissions' do
      let(:permissions) { ['video.video.manage'] }

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
      let(:permissions) { [] }

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
