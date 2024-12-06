# frozen_string_literal: true

require 'rspec'
require 'xikolo/s3'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir['spec/support/**/*.rb'].each {|f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

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

  config.before do
    %i[@resource @config].each do |variable|
      next unless Xikolo::S3.instance_variable_defined? variable

      Xikolo::S3.remove_instance_variable variable
    end

    Xikolo.config.s3 = {
      'connect_info' => {
        'endpoint' => 'https://s3.xikolo.de',
        'region' => 'default',
        'access_key_id' => 'access_key',
        'secret_access_key' => 'secret_access_key',
        'force_path_style' => true,
      },
      'buckets' => {
        'uploads' => 'xikolo-uploads',
      },
    }
  end
end
