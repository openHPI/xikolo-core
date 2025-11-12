# frozen_string_literal: true

# Ensure Draper uses the main application's ApplicationController for decorators in this engine
Rails.application.config.to_prepare do
  Draper.configure do |config|
    config.default_controller = PinboardService::ApplicationController
  end
end
