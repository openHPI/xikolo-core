# frozen_string_literal: true

require 'spec_helper'

describe 'Video: Subtitles: Destroy', type: :request do
  subject(:destroy_subtitle) { delete "/subtitles/#{subtitle.id}" }

  let!(:subtitle) { create(:video_subtitle, :with_cues) }
  let(:user) { create(:'account_service/user') }
  let(:authenticate) { true }

  before { sign_in(user:) }

  it 'is forbidden without proper permissions' do
    destroy_subtitle
    expect(response).to redirect_to root_url
    expect(request.flash['error'].first).to eq 'You do not have sufficient permissions for this action.'
  end

  context 'with permission' do
    let(:user) { create(:'account_service/user', :admin) }

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
    subject(:destroy_subtitle) { delete "/subtitles/#{generate(:uuid)}" }

    let(:user) { create(:'account_service/user', :admin) }

    it 'returns not found' do
      destroy_subtitle
      expect(response).to have_http_status :not_found
    end
  end
end
