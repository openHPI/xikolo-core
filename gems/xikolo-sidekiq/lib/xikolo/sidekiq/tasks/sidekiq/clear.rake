# frozen_string_literal: true

require 'sidekiq/api'

namespace :sidekiq do
  desc <<~DESC
    Flush all Sidekiq queues
  DESC
  task clear: :environment do
    Sidekiq::Queue.new.clear
    Sidekiq::RetrySet.new.clear
  end
end
