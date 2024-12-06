# frozen_string_literal: true

require 'sidekiq'

module Xikolo::Sidekiq
  class Railtie < ::Rails::Railtie
    # If the Rails app uses ActiveJob, tell it to use Sidekiq as backend
    if config.respond_to?(:active_job)
      config.active_job.queue_adapter = :sidekiq
    end

    # Setup Sidekiq Redis connection as configured in config/sidekiq_redis.yml
    initializer :sidekiq_connection do |app|
      redis_config = app.config_for(:sidekiq_redis) || {}

      # Optional: Redis Sentinel support
      # Both Sidekiq server and client do write operations, so we always need
      # to connect to the master.
      if redis_config[:sentinels]
        redis_config[:role] = 'master'
      end

      ::Sidekiq.configure_server do |config|
        config.redis = redis_config
      end

      ::Sidekiq.configure_client do |config|
        config.redis = redis_config

        # The default logger level is INFO. Reduce noise in the test runs.
        if Rails.env.test?
          config.logger.level = Logger::WARN
        end
      end
    end

    # For services that want to implement cronjobs, we automatically configure
    # the sidekiq-cron gem via a config/cron.yml file
    initializer :sidekiq_cron do |app|
      next unless Sidekiq.server?
      next unless defined? Sidekiq::Cron::Job

      # By using an after_initialize callback, we make sure that Redis can be
      # configured properly before we try to store any cron job information.
      app.config.after_initialize do
        # rubocop:disable Rails/FindEach
        # `Sidekiq::Cron::Job.all` returns an array and not Active Record
        # relation, so `find_each` is not defined.
        Sidekiq::Cron::Job.all.each(&:destroy)
        # rubocop:enable Rails/FindEach
        Sidekiq::Cron::Job.load_from_hash! app.config_for(:cron) || {}
      end
    end

    rake_tasks do
      load File.expand_path('tasks/sidekiq/clear.rake', __dir__)
    end
  end
end
