# frozen_string_literal: true

require 'spec_helper'

describe 'Video: Subtitles: Destroy', type: :request do
  subject(:destroy_subtitle) { delete "/subtitles/#{subtitle.id}", headers: }

  let!(:subtitle) { create(:video_subtitle, :with_cues) }
  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:permissions) { [] }

  before { stub_user_request(permissions:) }

  it 'is forbidden without proper permissions' do
    destroy_subtitle
    expect(response).to redirect_to root_url
    expect(request.flash['error'].first).to eq 'You do not have sufficient permissions for this action.'
  end

  context 'with permission' do
    let(:permissions) { %w[video.subtitle.manage] }

    it 'removes the subtitle from the database' do
      expect { destroy_subtitle }.to change(Video::Subtitle, :count).from(1).to(0)
    end

    it 'triggers a sync with the video provider' do
      expect { destroy_subtitle }.to have_enqueued_job(Video::SyncSubtitlesJob)
        .with(subtitle.video_id, 'en')
        .on_queue('default')
    end
  end

  describe '(error handling)' do
    subject(:destroy_subtitle) { delete "/subtitles/#{generate(:uuid)}", headers: }

    let(:permissions) { %w[video.subtitle.manage] }

    it 'returns not found' do
      destroy_subtitle
      expect(response).to have_http_status :not_found
    end
  end
end
