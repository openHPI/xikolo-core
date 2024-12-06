# frozen_string_literal: true

require 'spec_helper'

describe 'Admin: Videos: Index', type: :request do
  subject(:index_action) { get '/videos', headers:, params: }

  let(:headers) { {Authorization: "Xikolo-Session session_id=#{stub_session_id}"} }
  let(:params) { {} }
  let(:page) { Capybara.string(response.body) }

  before do
    stub_user_request(permissions: %w[video.video.manage])

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
      expect(results.first.find('td:nth-child(5)').text).to eq '2013-12-05 15:00:00 +0000'
      expect(results.last.find('td:nth-child(2)').text).to eq 'Old stream'
      expect(results.last.find('td:nth-child(5)').text).to eq '2013-10-01 18:30:00 +0000'
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
