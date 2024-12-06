# frozen_string_literal: true

if Rails.env.integration?
  require 'sidekiq/api'
  XiIntegration.hook :test_setup do
    Sidekiq::Queue.new.clear
    Sidekiq::ScheduledSet.new.clear
    Sidekiq::RetrySet.new.clear
  end
end
