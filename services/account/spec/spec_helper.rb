# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter,
]

if (brand = ENV.fetch('BRAND', nil))
  SimpleCov.command_name "RSpec-#{brand}"
end

require File.expand_path('../config/environment', __dir__)

require 'rspec/rails'
require 'webmock/rspec'

require 'restify'
require 'restify/adapter/typhoeus'

Restify.adapter = Restify::Adapter::Typhoeus.new(sync: true)

# Truncate log
Rails.root.join('log', 'test.log').write('')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').each {|f| require f }
Rails.root.glob('spec/brand/shared_examples/*.rb').each {|f| require f }

# Maintain test schema
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.order = 'random'
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.file_fixture_path = 'spec/support/files'

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.include WebMock::API
  config.include FactoryBot::Syntax::Methods
  config.include Rails.application.routes.url_helpers
  config.include ActiveJob::TestHelper, type: :job
  config.include ActiveJob::TestHelper, type: :request

  config.before do
    default_url_options[:host] = 'test.host'
  end

  config.before do
    stub_request(:any, /account\.xikolo\.tld/)
      .to_rack(Xikolo::Account::Application)
    stub_request(:any, /test\.host/)
      .to_rack(Xikolo::Account::Application)
  end

  config.after do
    Timecop.return
  end

  config.before do
    ActiveJob::Base.queue_adapter = :test
  end

  config.before do
    Rails.cache.clear
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
