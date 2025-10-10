# frozen_string_literal: true

require 'spec_helper'

describe 'Statistics: PlatformStatistics: learners_and_enrollments', type: :request do
  subject(:learners_and_enrollments) do
    get '/admin/platform_statistics/learners_and_enrollments',
      headers: {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"}
  end

  let(:json) { response.parsed_body }

  let(:enrollment_statistics) { build(:'course:enrollment:statistics') }

  let(:user_id) { SecureRandom.uuid }
  let(:permissions) { [] }

  before do
    stub_user_request(permissions:)

    Stub.service(:account, build(:'account:root'))
    Stub.service(:course, build(:'course:root'))
    Stub.request(:account, :get, '/statistic')
      .to_return Stub.json(enrollment_statistics['account'])
    Stub.request(:course, :get, '/stats?key=global')
      .to_return Stub.json(enrollment_statistics['course'])
  end

  context 'without permission' do
    it 'the controller responds with forbidden error' do
      learners_and_enrollments
      expect(json).to eq({'errors' => 'forbidden'})
    end
  end

  context 'with permission' do
    let(:permissions) { ['global.dashboard.show'] }

    it 'the controller responds with the learners and enrollment data' do
      learners_and_enrollments
      expect(json).to eq({
        'confirmed_users' => 217,
        'confirmed_users_last_day' => 0,
        'deleted_users' => 0,
        'total_enrollments' => 217,
        'total_enrollments_last_day' => 0,
        'courses_count' => 0,
      })
    end
  end
end
