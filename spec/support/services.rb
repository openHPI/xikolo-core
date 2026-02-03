# frozen_string_literal: true

RSpec.shared_context 'account_service API controller', shared_context: :metadata do
  routes { AccountService::Engine.routes }

  before do
    request.headers['ACCEPT'] = 'application/json'
    request.headers['CONTENT_TYPE'] = 'application/json'
  end
end

RSpec.shared_context 'course_service API controller', shared_context: :metadata do
  routes { CourseService::Engine.routes }
end

RSpec.shared_context 'notification_service controller', shared_context: :metadata do
  routes { NotificationService::Engine.routes }
end

RSpec.shared_context 'pinboard_service API controller', shared_context: :metadata do
  routes { PinboardService::Engine.routes }

  before do
    request.headers['ACCEPT'] = 'application/json'
    request.headers['CONTENT_TYPE'] = 'application/json'
  end
end

RSpec.shared_context 'timeeffort_service API controller', shared_context: :metadata do
  routes { TimeeffortService::Engine.routes }

  before do
    request.headers['ACCEPT'] = 'application/json'
    request.headers['CONTENT_TYPE'] = 'application/json'
  end
end

RSpec.shared_context 'quiz_service API controller', shared_context: :metadata do
  routes { QuizService::Engine.routes }
end

RSpec.configure do |config|
  config.before(:each) do
    Stub.enable(:account)
    Stub.enable(:course)
    Stub.enable(:notification)
    Stub.enable(:pinboard)
    Stub.enable(:timeeffort)
    Stub.enable(:quiz)
    Stub.enable(:news)

    stub_request(:any, /account_service|quiz_service|pinboard_service|notification_service|course_service|timeeffort_service|news_service/).to_rack(
      Rack::Builder.new do
        use Rack::Session::Cookie, key: '_test_session', secret: Rails.application.secret_key_base
        run Rails.application
      end
    )
  end
end

RSpec.configure do |config|
  config.before(:each, type: :request) do |example|
    if example.metadata[:location].match?(/account_service|quiz_service|pinboard_service|timeeffort_service/)
      host! 'test.host'
    end
  end
end
