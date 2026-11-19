# frozen_string_literal: true

require 'rspec/rebound'

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true

  # Only retry system tests
  config.around :each, type: :system do |example|
    example.run_with_retry retry: 2
  end

  config.retry_callback = proc do
    Capybara.reset!
  end
end
