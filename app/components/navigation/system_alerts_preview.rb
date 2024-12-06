# frozen_string_literal: true

module Navigation
  class SystemAlertsPreview < ViewComponent::Preview
    # To create an alert, open the rails console and
    # use the following:
    #
    # Alert.create!(
    #   publish_at: 1.hour.ago,
    #   publish_until: 2.hours.from_now,
    #   translations: {
    #     'en' => {
    #       'title' => 'Planned downtime',
    #       'text' => 'The _platform_ will be **unavailable for the next hour or so**.
    #       For further information on downtimes [refer to this page](https://en.wikipedia.org/wiki/Downtime).',
    #     },
    #   }
    # )
    #
    # The text property in translations can be written in Markdown.

    def new_alerts
      render Navigation::SystemAlerts.new(cookies: {})
    end
  end
end
