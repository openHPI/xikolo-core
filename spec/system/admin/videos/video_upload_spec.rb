# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Upload a video', type: :system do
  let(:video) { Rails.root.join('spec/support/files/video-sd.mp4').to_s }

  before do
    sign_in(user: create(:'account_service/user', :admin))
  end

  it 'uploads a video and creates a pending Bunny stream' do
    visit '/videos/new'

    expect(page).to have_text 'Upload a video'

    fill_in 'Title', with: 'My uploaded video'
    attach_file 'Select video', video
    find('input[type="submit"]').click

    expect(page).to have_text 'The video has been uploaded and is being processed.'

    stream = Video::Stream.last
    expect(stream.title).to eq 'My uploaded video'
    expect(stream.provider.provider_type).to eq 'bunny'
    expect(stream.video).to be_attached
    expect(stream.provider_video_id).to be_nil
    expect(stream.upload_state).to eq 'waiting'

    expect(enqueued_jobs.find {|j| j[:job] == UploadStreamToBunnyJob }).to be_present
  end

  it 'shows the upload status and lets a failed upload be retried' do
    stream = create(:stream, :bunny, title: 'My failed video',
      provider_video_id: 'guid-failed',
      hls_url: 'https://cdn.example.com/guid-failed/playlist.m3u8',
      upload_state: 'failed',
      upload_error: 'Bunny returned HTTP 503')

    visit '/videos'

    expect(page).to have_text 'My failed video'
    expect(page).to have_text 'Failed'

    find('[aria-label="More actions"]').click
    within '[data-behaviour="menu-dropdown"]' do
      click_on 'Retry upload'
    end
    within '[role=dialog][aria-modal=true]' do
      click_on 'Yes, sure'
    end

    expect(page).to have_text 'The video upload will be retried.'
    expect(stream.reload.upload_state).to eq 'waiting'
    expect(stream.upload_error).to be_nil
    expect(enqueued_jobs.find {|j| j[:job] == UploadStreamToBunnyJob }).to be_present
  end
end
