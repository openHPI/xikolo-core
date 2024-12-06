# frozen_string_literal: true

require 'bundler'
Bundler.setup :default, :test

require 'gurke'
require 'gurke/rspec'
require 'erb'

ENV['GURKE'] = 'true'

$LOAD_PATH << Gurke.root.join('support/lib')

Dir[Gurke.root.join('support/*.rb')].each {|path| require path }
load Gurke.root.join('support/ext/context.rb')

RSpec::Expectations.configuration.tap do |config|
  config.on_potential_false_positives = :raise
end

Gurke.configure do |config|
  if ENV.key? 'CI'
    config.default_retries = 1
    config.flaky_retries = 3
  else
    config.default_retries = 0
    config.flaky_retries = 0
  end

  config.before(:features) do
    # Reload steps for DRb usage
    Dir[Gurke.root.join('steps/**/*.rb')].each {|path| load path }
    Dir[Gurke.root.join('support/ext/**/*.rb')].each {|path| load path }
    Xikolo::Config.reload
  end
end
