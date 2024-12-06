# frozen_string_literal: true

require 'etc'

environment 'production'

preload_app!

tc = ENV.fetch('CONCURRENCY', ENV.fetch('RAILS_MAX_THREADS', 16))
threads tc, tc
workers ENV.fetch('WORKERS', Etc.nprocessors.clamp(2, 8))

before_fork do
  ActiveRecord::Base.connection.disconnect!
  Msgr.client.stop if defined?(Msgr)
end

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end

plugin :tmp_restart
