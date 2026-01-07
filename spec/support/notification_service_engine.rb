# frozen_string_literal: true

RSpec.shared_context 'notification_service controller', shared_context: :metadata do
  routes { NotificationService::Engine.routes }
end

RSpec.configure do |config|
  config.before(:each) do |example|
    if example.metadata[:location].include?('notification_service')

      Stub.service(:course, build(:'course:root'))
      Stub.service(:account, build(:'account:root'))

      stub_request(:any, /notification_service/).to_rack(
        Rack::Builder.new do
          use Rack::Session::Cookie, key: '_test_session', secret: Rails.application.secret_key_base
          run Rails.application
        end
      )
    end
  end
end
