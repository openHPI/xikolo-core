# frozen_string_literal: true

module Navigation
  class SystemAlertsPreview < ViewComponent::Preview
    def new_alerts
      render Navigation::SystemAlerts.new(cookies: {})
    end
  end
end
