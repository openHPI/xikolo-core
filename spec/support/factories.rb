# frozen_string_literal: true

require 'factory_bot'

RSpec.configure do |config|
  # Include factory DSL into all specs
  config.include FactoryBot::Syntax::Methods
end
