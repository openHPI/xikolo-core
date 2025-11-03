# frozen_string_literal: true

require 'account_service/provider'
require 'account_service/paginator'
require 'account_service/responders/api'

module AccountService
  class Engine < ::Rails::Engine
    isolate_namespace AccountService
    config.generators.api_only = true
  end
end
