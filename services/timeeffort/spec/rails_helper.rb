# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!
require 'sidekiq/testing'

require 'webmock'
require 'webmock/rspec'

require 'xikolo/common/rspec'

require 'restify'
require 'restify/adapter/typhoeus'

Restify.adapter = Restify::Adapter::Typhoeus.new(sync: true)

Sidekiq::Testing.fake!

require 'database_cleaner'

# Truncate log
Rails.root.join('log', 'test.log').write('')

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').each {|f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

module Helpers
  def json(hash)
    hash.as_json
  end
end

RSpec.configure do |config|
  config.include Helpers
  config.include WebMock::API
  config.include Rails.application.routes.url_helpers
  config.include FactoryBot::Syntax::Methods
  config.include ActiveJob::TestHelper, type: :job

  config.before do
    default_url_options[:host] = 'test.host'
  end

  config.before do
    stub_request(:any, /test\.host/)
      .to_rack(Xikolo::TimeEffort::Application)
  end

  config.before do
    ActiveJob::Base.queue_adapter = :test
  end

  config.around do |example|
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.cleaning(&example)
  end

  config.before(:all) do
    DatabaseCleaner.clean_with :truncation
  end

  config.after do
    # Clear draper view context to avoid leaking host name
    Draper::ViewContext.clear!
  end

  # Flush RabbitMQ consumer queues
  config.after do
    Msgr.client.stop delete: true
    Msgr::TestPool.reset
  end
end
