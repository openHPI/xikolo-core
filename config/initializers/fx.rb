# frozen_string_literal: true

# Since we want to use functions as default values for column, we must
# declare them before tables
Fx.configure do |config|
  config.dump_functions_at_beginning_of_schema = true
end
