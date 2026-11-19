# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Videos: Index', type: :request do
  subject(:index_action) { get '/videos', params: }

  let(:params) { {} }
  let(:page) { Capybara.string(response.body) }

  def status_text_for(title)
    index_action
    row = page.find_all('.stream').find {|r| r.find('td:nth-child(2)').text == title }
    row.find('td:nth-child(3)').text.strip.squeeze(' ')
  end

  before do
    sign_in(user: create(:'account_service/user', :admin))

    create(:stream, title: 'New stream', created_at: DateTime.new(2013, 12, 0o5, 15, 0o0))
    create(:stream, title: 'Old stream', created_at: DateTime.new(2013, 10, 0o1, 18, 30))
  end

  context 'without search params' do
    it 'shows a list of streams' do
      index_action
      expect(page).to have_text 'Filter videos starting with:'
      expect(page).to have_text 'New stream'
      expect(page).to have_text 'Old stream'
    end

    it 'shows streams sorted by creation date in descending order' do
      index_action

      results = page.find_all('.stream')
      expect(results.first.find('td:nth-child(2)').text).to eq 'New stream'
      expect(results.first.find('td:nth-child(6)').text).to eq '2013-12-05 15:00:00 +0000'
      expect(results.last.find('td:nth-child(2)').text).to eq 'Old stream'
      expect(results.last.find('td:nth-child(6)').text).to eq '2013-10-01 18:30:00 +0000'
    end
  end

  context 'for Bunny streams with different upload states' do
    let(:bunny_provider) { create(:video_provider, :bunny, name: 'Bunny') }

    before do
      create(:stream, provider: bunny_provider, title: 'Waiting stream',
        provider_video_id: nil, hd_url: nil, sd_url: nil, hls_url: nil, upload_state: 'waiting')
      create(:stream, provider: bunny_provider, title: 'Uploading stream',
        provider_video_id: 'guid-up', hls_url: 'https://cdn.example.com/guid-up/playlist.m3u8', upload_state: 'uploading')
      create(:stream, provider: bunny_provider, title: 'Ready stream')
      create(:stream, provider: bunny_provider, title: 'Invalid stream',
        provider_video_id: nil, hd_url: nil, sd_url: nil, hls_url: nil,
        upload_state: 'failed', upload_error: 'Bunny is down')
      create(:stream, provider: bunny_provider, title: 'Failed stream',
        provider_video_id: 'guid-fail', hls_url: 'https://cdn.example.com/guid-fail/playlist.m3u8',
        upload_state: 'failed', upload_error: 'Bunny is down')
    end

    it 'shows a Waiting badge for waiting streams' do
      expect(status_text_for('Waiting stream')).to eq 'Waiting'
    end

    it 'shows an Uploading badge for uploading streams' do
      expect(status_text_for('Uploading stream')).to eq 'Uploading'
    end

    it 'shows a Ready badge for ready streams' do
      expect(status_text_for('Ready stream')).to eq 'Ready'
    end

    it 'shows an Invalid badge for failed streams without a provider video' do
      expect(status_text_for('Invalid stream')).to eq 'Invalid'
    end

    it 'shows a Failed badge for failed streams with a provider video' do
      expect(status_text_for('Failed stream')).to eq 'Failed'
    end

    it 'shows no status badge for provider-synced streams' do
      index_action
      row = page.find_all('.stream').find {|r| r.find('td:nth-child(2)').text == 'New stream' }
      expect(row.find('td:nth-child(3)').text).to be_blank
    end
  end

  context 'with search params' do
    let(:params) { super().merge(prefix: 'content-ab') }

    before do
      create(:stream, title: 'content-ab-pip-stream-hd1', created_at: 1.hour.ago)
      create(:stream, title: 'content-ab-pip-stream-sd1', created_at: 2.hours.ago)
    end

    it 'filters the streams, displaying them in alphabetical order' do
      index_action

      results = page.find_all('.stream')
      expect(results.first.find('td:nth-child(2)').text).to eq 'content-ab-pip-stream-hd1'
      expect(results.last.find('td:nth-child(2)').text).to eq 'content-ab-pip-stream-sd1'
      expect(page).to have_no_text 'New stream'
      expect(page).to have_no_text 'Old stream'
    end

    context 'when the title of the streams is in different cases' do
      before do
        create(:stream, title: 'content-ab-ZZ-pip-stream-hd1')
      end

      it 'filters the streams case-insensitively, displaying them in alphabetical order' do
        index_action

        results = page.find_all('.stream')
        expect(results.first.find('td:nth-child(2)').text).to eq 'content-ab-pip-stream-hd1'
        expect(results.last.find('td:nth-child(2)').text).to eq 'content-ab-ZZ-pip-stream-hd1'
      end
    end
  end
end
