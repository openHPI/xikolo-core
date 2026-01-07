# frozen_string_literal: true

RSpec.shared_context 'notification_service controller', shared_context: :metadata do
  routes { NotificationService::Engine.routes }
end
