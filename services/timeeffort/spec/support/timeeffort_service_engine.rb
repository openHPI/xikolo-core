# frozen_string_literal: true

RSpec.shared_context 'timeeffort_service API controller', shared_context: :metadata do
  routes { TimeeffortService::Engine.routes }
end
