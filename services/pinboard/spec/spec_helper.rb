# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'simplecov-teamcity-summary'

if ENV['TEAMCITY_VERSION']
  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::TeamcitySummaryFormatter,
  ]
end

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'webmock/rspec'
require 'sidekiq/testing'

require 'xikolo/common/rspec'

require 'restify'
require 'restify/adapter/typhoeus'

Restify::Registry.store :test, 'http://pinboard.xikolo.tld',
  adapter: Restify::Adapter::Typhoeus.new(sync: true)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').each {|f| require f }

# Maintain test schema
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.example_status_persistence_file_path = 'spec/examples.txt'

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.include WebMock::API
  config.include FactoryBot::Syntax::Methods

  config.before do
    # Delegate all request to service rack app
    stub_request(:any, /pinboard\.xikolo\.tld/).to_rack(Xikolo::PinboardService::Application)

    # Explicit clear directly used Rails caches
    Rails.cache.clear

    # Remove all queued background worker
    # e.g. leftovers from specs that do not ron jobs at all
    Sidekiq::Worker.clear_all

    # Reset msgr
    Msgr.client.stop delete: true
    Msgr::TestPool.reset
  end

  config.after(:all) do
    Msgr.client.stop delete: true
    Msgr::TestPool.reset
  end
end

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end
