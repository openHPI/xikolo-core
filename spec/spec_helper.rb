# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

# TODO: Remove when inegration tests use the services in Web
ENV['XIKOLO_SERVICE_ACCOUNT'] = 'http://localhost:3000/account_service'

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
require 'acfs/rspec'
require 'rspec/rails'
require 'sidekiq/testing'
require 'webmock/rspec'

require 'xikolo/common/rspec'

require 'restify'
require 'restify/adapter/typhoeus'
Restify.adapter = Restify::Adapter::Typhoeus.new(sync: true)

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

  config.example_status_persistence_file_path = 'spec/examples.txt'

  OmniAuth.config.add_mock(:identity,
    uid: '1',
    name: 'peter pan',
    email: 'peter@pan.de')

  config.include JsonSpec::Helpers
  config.include ActiveJob::TestHelper, type: :job
  config.include ActiveJob::TestHelper, type: :model

  config.include RestifyHelper

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

  config.before(:suite) do
    # Disable HTTP requests, but allow 127.0.0.1 connection for selenium/capybara.
    # This assumes services are *not* configured to use 127.0.0.1.
    WebMock.disable_net_connect!(allow: '127.0.0.1')

    Acfs::Stub.allow_requests = true
  end

  config.before do
    OmniAuth.config.test_mode = true

    Sidekiq::Worker.clear_all
  end

  config.around do |example|
    # Around runs before before hook, and we must set the queue_adapter
    # before around hooks in specs are run, such as:
    #
    #     around {|example| perform_enqueued_jobs(&example) }
    #
    ActiveJob::Base.queue_adapter = :test

    example.run
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

RSpec::Matchers.define :_have_xpath do |expected, **opts|
  match do |actual|
    return false if Nokogiri::HTML(actual).xpath(expected).empty?

    if opts.key?(:text) && Nokogiri::HTML(actual).xpath("#{expected}/text()").to_s != opts[:text]
      return false
    end
    if opts.key?(:content) && Nokogiri::HTML(actual).xpath("#{expected}/@content").to_s != opts[:content]
      return false
    end

    true
  end
  failure_message do |actual|
    if Nokogiri::HTML(actual).xpath(expected).empty?
      return "expected #{actual} to have xpath #{expected}"
    end

    if opts.key?(:text)
      text = Nokogiri::HTML(actual).xpath("#{expected}/text()").to_s
      return "expected text node of xpath #{expected} to eq #{opts[:text]}, but was #{text}"
    end
    if opts.key?(:content)
      text = Nokogiri::HTML(actual).xpath("#{expected}/@content").to_s
      return "expected content of xpath #{expected} to eq #{opts[:content]}, but was #{text}"
    end
    "expected #{actual} to have xpath #{expected} with options #{opts}"
  end
  failure_message_when_negated do |actual|
    if Nokogiri::HTML(actual).xpath(expected).empty?
      return "expected #{actual} not to have xpath #{expected}"
    end

    if opts.key?(:text)
      text = Nokogiri::HTML(actual).xpath("#{expected}/text()").to_s
      return "expected text node of xpath #{expected} not to eq #{opts[:text]}, but was #{text}"
    end
    if opts.key?(:content)
      text = Nokogiri::HTML(actual).xpath("#{expected}/@content").to_s
      return "expected content of xpath #{expected} not to eq #{opts[:content]}, but was #{text}"
    end
    "expected #{actual} not to have xpath #{expected} with options #{opts}"
  end
end
