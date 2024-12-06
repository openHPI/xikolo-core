# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Lanalytics Bridge API: Root', type: :request do
  subject(:root) do
    get '/bridges/lanalytics', headers:
  end

  let(:token) { 'Bearer 78f6d8ca88c65a67c9dffa3c232313d64b4e338e29d7c83ef39c2e963894b966' }
  let(:headers) { {'Authorization' => token} }
  let(:json) { JSON.parse response.body }

  context 'when trying to authorize with an invalid token' do
    let(:headers) { {'Authorization' => 'Bearer invalid'} }

    it 'responds with 401 Unauthorized' do
      root

      expect(response).to have_http_status :unauthorized
    end
  end

  it 'links to all top-level resources' do
    root

    expect(json).to match({
      'course_open_badge_stats_url' => 'http://www.example.com/bridges/lanalytics/courses/{course_id}/open_badge_stats',
      'course_ticket_stats_url' => 'http://www.example.com/bridges/lanalytics/courses/{course_id}/ticket_stats',
    })
  end
end
