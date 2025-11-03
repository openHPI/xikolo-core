# frozen_string_literal: true

# Configure database cleaning and isolation for specs. This include some
# exceptions and flags to control the behavior for specific specs.

RSpec.configure do |config|
  config.use_transactional_fixtures = true
end
