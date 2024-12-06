# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'webmock/rspec'
require 'sidekiq/testing'

require 'xikolo/common/rspec'

require 'restify'
require 'restify/adapter/typhoeus'

Restify::Registry.store :test, 'http://peerassessment.xikolo.tld',
  adapter: Restify::Adapter::Typhoeus.new(sync: true)

Sidekiq::Testing.fake!

require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').each {|f| require f }

# Maintain test schema
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    # Only allow expect syntax
    c.syntax = :expect
  end

  # Sidekiq testing config
  config.before do
    Sidekiq::Worker.clear_all
  end

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

  # Additional helpers
  config.include TrainingSpecHelper

  config.include WebMock::API
  config.include FactoryBot::Syntax::Methods

  # Delegate all request to service rack app
  config.before(:all) do
    WebMock.disable_net_connect!
  end

  config.before do
    stub_request(:any, /peerassessment\.xikolo\.tld/)
      .to_rack(Xikolo::PeerAssessment::Application)
  end

  config.around do |example|
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.cleaning(&example)
  end

  config.before(:all) do
    DatabaseCleaner.clean_with :truncation
  end

  config.after do
    Msgr::TestPool.reset
  end

  config.after(:all) do
    Msgr.client.stop delete: true
  end
end

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end
