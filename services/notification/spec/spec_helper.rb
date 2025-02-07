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

if (brand = ENV.fetch('BRAND', nil))
  SimpleCov.command_name "RSpec-#{brand}"
end

require File.expand_path('../config/environment', __dir__)

require 'rspec/rails'
require 'sidekiq/testing'
require 'webmock/rspec'

require 'xikolo/common/rspec'

require 'restify'
require 'restify/adapter/typhoeus'

Restify::Registry.store :test, 'http://notification.xikolo.tld',
  adapter: Restify::Adapter::Typhoeus.new(sync: true)

Sidekiq::Testing.inline!

require 'uri'

# Truncate log
Rails.root.join('log', 'test.log').write('')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').each {|f| require f }

# Maintain test schema
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join('spec/fixtures')]

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

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://myronmars.to/n/dev-blog/2012/06/rspecs-new-expectation-syntax
    expectations.syntax = :expect
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Enable only the newer, non-monkey-patching expect syntax.
    # For more details, see:
    #   - http://teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
    mocks.syntax = :expect

    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended.
    mocks.verify_partial_doubles = true
  end

  # Include FactoryBot DSL in specs
  config.include FactoryBot::Syntax::Methods

  # Delegate all request to service rack app
  config.include WebMock::API
  config.before do
    stub_request(:any, /notification\.xikolo\.tld/)
      .to_rack(Xikolo::NotificationService::Application)
    stub_request(:any, /test\.host/)
      .to_rack(Xikolo::NotificationService::Application)
    I18n.locale = Xikolo.config.locales['default']
  end

  config.after do
    ActionMailer::Base.deliveries.clear
  end

  config.around do |example|
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.cleaning(&example)
  end

  config.before(:all) do
    DatabaseCleaner.clean_with :truncation
  end

  config.after do
    Msgr.client.stop delete: true
    Msgr::TestPool.reset
  end

  config.after(:all) do
    Msgr.client.stop delete: true
  end
end

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end
