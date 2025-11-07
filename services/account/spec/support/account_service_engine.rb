# frozen_string_literal: true

RSpec.shared_context 'account_service API controller', shared_context: :metadata do
  routes { AccountService::Engine.routes }
end
