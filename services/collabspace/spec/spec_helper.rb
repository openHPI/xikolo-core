# frozen_string_literal: true

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

  config.expect_with :rspec do |c|
    # Do not truncate failing expectations with diffs
    c.max_formatted_output_length = nil
  end

  config.include WebMock::API
  config.include FactoryBot::Syntax::Methods

  # Delegate all request to service rack app
  config.before do
    stub_request(:any, /test\.host/).to_rack(Xikolo::CollabSpace::Application)
  end

  config.before do
    ActiveJob::Base.queue_adapter = :test
  end

  # Flush RabbitMQ consumer queues
  config.after do
    Msgr.client.stop delete: true
    Msgr::TestPool.reset
  end
end

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end
