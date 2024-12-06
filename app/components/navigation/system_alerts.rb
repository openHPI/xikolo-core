# frozen_string_literal: true

module Navigation
  class SystemAlerts < ApplicationComponent
    def initialize(cookies:)
      @cookies = cookies
    end

    private

    def render?
      alerts.any?
    end

    def aria_expanded
      alerts.any? {|a| a[:new?] } ? 'true' : 'false'
    end

    def seen_alerts
      @seen_alerts ||= @cookies['seen_alerts'].to_s.split(',')
    end

    # A value that should be stored for the user when opening the alerts list,
    # marking all current alerts as read for the next request.
    def remember_value
      alerts.pluck(:id).join(',')
    end

    # Returns a list of currently active system alerts.
    # * When new alerts appear, a popover will alert users to that fact,
    # nudging them to open the dropdown to read the alerts.
    # * Once users have seen alerts (or dismissed the popover), alerts will
    # still be available through the dropdown, but the popover will no
    # longer be shown.
    def alerts
      @alerts ||= cached_system_alerts.map do |alert|
        alert.merge(new?: seen_alerts.exclude?(alert[:id]))
      end
    end

    # Caches the list of alerts (per language) for five minutes.
    # * The list of IDs of alerts that were "seen" is remembered per machine,
    # using a cookie named "seen_alerts". It is written by JavaScript
    # whenever alerts are marked as read.
    def cached_system_alerts
      Rails.cache.fetch(
        "system_alerts_#{I18n.locale}.v1",
        expires_in: 5.minutes
      ) do
        Alert.published.by_publication_date.map do |alert|
          translation = alert.try_translation I18n.locale.to_s
          {
            id: alert.id,
            title: translation.title,
            text: translation.text,
          }
        end
      end
    end
  end
end
