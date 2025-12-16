# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter,
]

require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'sidekiq/testing'
require 'webmock/rspec'
require 'paper_trail/frameworks/rspec'

require 'xikolo/common/rspec'

require 'restify'
require 'restify/adapter/typhoeus'

Restify.adapter = Restify::Adapter::Typhoeus.new(sync: true)

Sidekiq::Testing.fake!

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').each {|f| require f }

# Maintain test schema
ActiveRecord::Migration.maintain_test_schema!

srand RSpec.configuration.seed

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  config.expect_with :rspec do |c|
    # Only allow expect syntax
    c.syntax = :expect
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
  config.example_status_persistence_file_path = 'spec/examples.txt'

  # Delegate all request to service rack app
  config.include WebMock::API
  config.include DefaultURLOptions
  config.include Rails.application.routes.url_helpers
  config.include FactoryBot::Syntax::Methods

  config.after :all do
    Msgr.client.stop delete: true
  end

  config.before do
    stub_request(:any, /www\.example\.com/).to_rack(Xikolo::CourseService::Application)

    CourseService::FileDeletionWorker.jobs.clear
    Rails.cache.clear
    Sidekiq::Worker.clear_all
  end

  config.after do
    Msgr.client.stop delete: true
    Msgr::TestPool.reset
    Timecop.return
  end
end

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end
