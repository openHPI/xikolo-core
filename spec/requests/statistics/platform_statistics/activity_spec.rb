# frozen_string_literal: true

require 'spec_helper'

describe 'Statistics: PlatformStatistics: activity', type: :request do
  subject(:request_activity) do
    get '/admin/platform_statistics/activity',
      headers: {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"}
  end

  let(:json) { response.parsed_body }

  let(:activity_statistics) { build(:'course:activity:statistics') }

  let(:user_id) { SecureRandom.uuid }
  let(:permissions) { [] }

  before do
    stub_user_request(permissions:)

    Stub.service(:learnanalytics, build(:'lanalytics:root'))
    Stub.request(:learnanalytics, :get, '/metrics')
      .to_return Stub.json([activity_statistics['activity']])
    Stub.request(:learnanalytics, :get, "/metrics/active_user_count?end_date=#{Time.zone.now}&start_date=#{1.day.ago}")
      .to_return Stub.json({'active_users' => 0})
    Stub.request(:learnanalytics, :get, "/metrics/active_user_count?end_date=#{Time.zone.now}&start_date=#{7.days.ago}")
      .to_return Stub.json({'active_users' => 0})
  end

  context 'without permission' do
    it 'responds with forbidden error' do
      request_activity
      expect(json).to eq({'errors' => 'forbidden'})
    end
  end

  context 'with permission' do
    let(:permissions) { ['global.dashboard.show'] }

    it 'responds with the activity data' do
      request_activity
      expect(json).to eq({
        'count_24h' => 0,
        'count_7days' => 0,
      })
    end
  end
end
