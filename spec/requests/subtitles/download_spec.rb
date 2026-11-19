# frozen_string_literal: true

require 'spec_helper'

describe 'Video: Subtitles: Download', type: :request do
  let(:download_subtitle) { get "/subtitles/#{subtitle.id}/download" }

  let!(:cue) { create(:subtitle_cue, identifier: 1, start: 0, stop: 10) }
  let(:subtitle) { cue.subtitle }

  let(:user) { create(:'account_service/user') }

  before { sign_in(user:) }

  describe '(response)' do
    context 'without permission' do
      it 'is forbidden without proper permissions' do
        download_subtitle
        expect(response).to redirect_to root_url
        expect(request.flash['error'].first).to eq 'You do not have sufficient permissions for this action.'
      end
    end

    context 'with permission' do
      before do
        role = create(:'account_service/role', permissions: ['video.subtitle.manage'])
        create(:'account_service/grant', principal: user, role:)
      end

      it 'responds with ok' do
        download_subtitle
        expect(response).to have_http_status(:ok)
      end

      it 'serves the subtitle as a downloadable WebVTT file' do
        download_subtitle
        expect(response.body).to start_with "WEBVTT\n\n"
      end

      it 'responds with the correct MIME type' do
        download_subtitle
        expect(response['Content-Type']).to eq 'text/vtt'
      end

      context 'when the video belongs to an item' do
        let!(:item) { create(:item, content_id: subtitle.video.id) }

        it 'uses item id, course code and language as file name' do
          download_subtitle
          filename = "#{UUID4(item.id).to_param}_#{item.course.course_code}_en.vtt"
          expect(response.headers['Content-Disposition']).to match(/attachment.*filename="#{filename}"/)
        end
      end

      context 'when the video is a teaser video' do
        let(:course) { create(:course) }

        before { create(:visual, course:, video: subtitle.video) }

        it 'uses course code and language as file name' do
          download_subtitle
          filename = "#{course.course_code}_en.vtt"
          expect(response.headers['Content-Disposition']).to match(/attachment.*filename="#{filename}"/)
        end
      end
    end
  end
end
