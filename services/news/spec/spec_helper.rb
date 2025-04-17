# frozen_string_literal: true

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

require 'xikolo/common/rspec'

require 'restify'
require 'restify/adapter/typhoeus'

Restify::Registry.store :test, 'http://news.xikolo.tld',
  adapter: Restify::Adapter::Typhoeus.new(sync: true)

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Rails.root.glob('spec/support/**/*.rb').each {|f| require f }

# Maintain test schema
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.order = 'random'
  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.include WebMock::API
  config.include FactoryBot::Syntax::Methods

  config.before do
    stub_request(:any, /news\.xikolo\.tld/)
      .to_rack(Xikolo::NewsService::Application)
    stub_request(:any, /test\.host/)
      .to_rack(Xikolo::NewsService::Application)
  end

  config.around do |example|
    strategy = example.metadata.fetch(:dbc, :transaction)
    DatabaseCleaner.strategy = strategy
    DatabaseCleaner.cleaning(&example)
  end

  config.before(:all) do
    DatabaseCleaner.clean_with :truncation
  end

  config.before do
    I18n.locale = I18n.default_locale
  end

  config.before do
    Stub.service(
      :course,
      enrollments_url: 'http://course.xikolo.tld/enrollments{?course_id,user_id,role,learning_evaluation,deleted,current_course,per_page,proctored}'
    )
  end
end

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end
