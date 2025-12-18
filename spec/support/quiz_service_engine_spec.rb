# frozen_string_literal: true

RSpec.shared_context 'quiz_service API controller', shared_context: :metadata do
  routes { QuizService::Engine.routes }
end

RSpec.configure do |config|
  config.before(:each, type: :request) do |example|
    if example.metadata[:location].include?('quiz_service')
      stub_request(:any, /quiz_service/).to_rack(
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
    if example.metadata[:location].include?('quiz_service')
      host! 'test.host'
    end
  end
end
