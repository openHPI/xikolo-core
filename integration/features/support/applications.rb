# frozen_string_literal: true

require 'fileutils'
require 'yaml'
require 'rack/remote'
require 'uuid4'

require 'xikolo/config'
require 'xikolo/s3'

Xikolo::Config.add_config_location File.expand_path('lib/xikolo.yml', __dir__)

require 'broadcast_receiver'
require 'server'
require_relative 'capybara_email'
require_relative 'capybara_downloads'

require Gurke.root.join('applications.rb')

BASE_URI = Addressable::URI.parse \
  ENV.fetch('BASE_URI', "http://127.0.0.1:#{Server[:web].port}")

# Truncate all logs
Server.each(:rails) do |app|
  log = app.file('log', 'integration.log')
  File.write(log, '') if File.exist?(log)
end

def services_config
  {'integration' => {
    'services' => Server.all_services.to_h do |app|
      [app.id.to_s, "http://127.0.0.1:#{Server[:web].port}/#{app.mount_path}"]
    end,
  }}
end

Gurke.configure do |config|
  config.before(:system) do
    Server.start_all
  end

  config.before(:scenario) do
    @__remote_test_id = SecureRandom.hex(64)
  end

  # Add a before and after hook for setup / teardown for every single service
  # This way, failures in one remote invocation will not prevent other invocations from being run, thereby preventing
  # a rather obnoxious family of mis-leading errors.
  Server.each do |app|
    config.before(:scenario) do
      counter ||= 0
      Rack::Remote.invoke app.id.to_sym, :test_case_setup, id: @__remote_test_id
    rescue Net::OpenTimeout
      counter += 1
      if counter <= Gurke.config.flaky_retries
        app.receiver.message app, :sys, 'Timeout during test_case_setup, retrying!'
        retry
      else
        raise
      end
    end

    config.after(:scenario) do
      counter ||= 0
      Rack::Remote.invoke app.id.to_sym, :test_case_teardown, id: @__remote_test_id
    rescue Net::OpenTimeout
      counter += 1
      if counter <= Gurke.config.flaky_retries
        app.receiver.message app, :sys, 'Timeout during test_case_teardown, retrying!'
        retry
      else
        raise
      end
    end
  end

  config.after(:system) do
    Server.stop_all
  end
end
