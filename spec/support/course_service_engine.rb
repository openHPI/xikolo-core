# frozen_string_literal: true

RSpec.shared_context 'course_service API controller', shared_context: :metadata do
  routes { CourseService::Engine.routes }
end

RSpec.configure do |config|
  config.before(:each, type: :request) do |example|
    if example.metadata[:location].include?('course_service')
      stub_request(:any, /course_service/).to_rack(
        Rack::Builder.new do
          use Rack::Session::Cookie, key: '_test_session', secret: Rails.application.secret_key_base
          run Rails.application
        end
      )
    end

    Stub.service(:course, build(:'course:root'))
  end
end
