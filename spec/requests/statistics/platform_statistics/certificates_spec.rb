# frozen_string_literal: true

require 'spec_helper'

describe 'Statistics: PlatformStatistics: certificates', type: :request do
  subject(:certificates) do
    get '/admin/platform_statistics/certificates',
      headers: {'Authorization' => "Xikolo-Session session_id=#{stub_session_id}"}
  end

  let(:json) { response.parsed_body }

  let(:certificate_statistics) { build(:'course:cerfiticate:statistics') }

  let(:user_id) { SecureRandom.uuid }
  let(:permissions) { [] }

  before do
    stub_user_request(permissions:)

    Stub.service(:learnanalytics, build(:'lanalytics:root'))
    Stub.request(:learnanalytics, :get, '/metrics')
      .to_return Stub.json([certificate_statistics['certificates']])
    Stub.request(:learnanalytics, :get, '/metrics/certificates')
      .to_return Stub.json(certificate_statistics['certificate_amounts'])
  end

  context 'without permission' do
    it 'the controller responds with forbidden error' do
      certificates
      expect(json).to eq({'errors' => 'forbidden'})
    end
  end

  context 'with permission' do
    let(:permissions) { ['global.dashboard.show'] }

    it 'the controller responds with the certificates data' do
      certificates
      expect(json).to eq({
        'cop_count' => 0,
        'roa_count' => 0,
      })
    end
  end
end
