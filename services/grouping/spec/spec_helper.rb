# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter,
]

require File.expand_path('../config/environment', __dir__)

require 'webmock/rspec'
require 'rspec/rails'
require 'rspec/its'

require 'sidekiq/testing'

require 'xikolo/common/rspec'

require 'restify'
require 'restify/adapter/typhoeus'

Restify::Registry.store :test, 'http://test.host',
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

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before(:suite) do
    # FactoryBot.lint
  end

  config.include WebMock::API
  config.before do
    # Delegate all request to service rack app
    stub_request(:any, /test\.host/)
      .to_rack(Xikolo::Grouping::Application)
    stub_request(:any, /grouping\.xikolo\.tld/)
      .to_rack(Xikolo::Grouping::Application)
    Sidekiq::Worker.clear_all # Do not linger jobs between specs
  end

  # Include FactoryBot DSL in specs
  config.include FactoryBot::Syntax::Methods

  config.around do |example|
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.cleaning(&example)
  end

  config.before(:all) do
    DatabaseCleaner.clean_with :truncation
  end

  config.before do
    Stub.service(
      :account,
      user_url: '/users/{id}',
      users_url: '/users{?search,query,blurb,archived,confirmed,id}',
      authorization_url: '/authorizations/{id}',
      authorizations_url: '/authorizations',
      group_url: '/groups/{id}',
      groups_url: '/groups',
      membership_url: '/memberships/{id}',
      memberships_url: '/memberships'
    )

    Stub.service(
      :course,
      course_url: '/courses/{id}',
      enrollments_url: '/enrollments'
    )

    Stub.service(
      :learnanalytics,
      metric_url: '/api/metrics/{name}{?user_id,course_id,start_date,end_date}'
    )
  end
end

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end
