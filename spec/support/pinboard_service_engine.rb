# frozen_string_literal: true

RSpec.shared_context 'pinboard_service API controller', shared_context: :metadata do
  routes { PinboardService::Engine.routes }

  before do
    request.headers['ACCEPT'] = 'application/json'
    request.headers['CONTENT_TYPE'] = 'application/json'
  end
end

RSpec.configure do |config|
  config.before(:each, type: :request) do |example|
    if example.metadata[:location].include?('pinboard_service')
      stub_request(:any, /pinboard_service/).to_rack(
        Rack::Builder.new do
          use Rack::Session::Cookie, key: '_test_session', secret: Rails.application.secret_key_base
          run Rails.application
        end
      )
    end
  end
end

RSpec.configure do |config|
  config.before(:each, type: :request) do |example|
    if example.metadata[:location].include?('pinboard_service')
      host! 'test.host'
    end
  end
end
