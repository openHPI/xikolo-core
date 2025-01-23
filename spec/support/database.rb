# frozen_string_literal: true

# Configure database cleaning and isolation for specs. This include some
# exceptions and flags to control the behavior for specific specs.

RSpec.configure do |config|
  # Do not use Rails' default transactional mode since some specs must
  # run outside of a transaction. Instead, we use database_cleaner as
  # configured below.
  config.use_transactional_fixtures = false

  config.before(:suite) do
    # Clean up database once, before any test runs so that nothing leaks
    # from previous runs or debugging sessions.
    DatabaseCleaner.clean_with :truncation
  end

  config.around do |example|
    # TODO: System specs with Capybara should work with the :transaction
    # strategy, but not all are.
    #
    # Some specs, marked with transaction: false, must be run outside a
    # transaction, usually because the test transactional correctness,
    # conflict handling, or concurrent operations.
    if example.metadata[:type] == :system || example.metadata[:transaction] == false
      DatabaseCleaner.strategy = :deletion
    else
      DatabaseCleaner.strategy = :transaction
    end

    DatabaseCleaner.cleaning(&example)
  end
end
