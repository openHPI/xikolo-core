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
require 'paper_trail/frameworks/rspec'

require 'xikolo/common/rspec'

require 'restify'
require 'restify/adapter/typhoeus'

Restify::Registry.store :test, 'http://quiz.xikolo.tld',
  adapter: Restify::Adapter::Typhoeus.new(sync: true)

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

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # Delegate all request to service rack app
  config.include WebMock::API
  config.before do
    stub_request(:any, /quiz\.xikolo\.tld/).to_rack(Xikolo::QuizService::Application)

    Sidekiq::Worker.clear_all
  end

  config.around do |example|
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.cleaning(&example)
  end

  config.before(:all) do
    DatabaseCleaner.clean_with :truncation
  end

  # simplify factory management in spec, simple call `create` ...
  config.include FactoryBot::Syntax::Methods
end

# extend gem-xikolo-common
FactoryBot.define do
  xikolo_uuid_sequence(:answer_id, service: 3800, resource: 3)
end

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end
