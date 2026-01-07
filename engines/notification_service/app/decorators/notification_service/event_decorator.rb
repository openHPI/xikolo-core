# frozen_string_literal: true

module NotificationService
class EventDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  include NotificationService::MailerHelper

  delegate_all

  def as_json(_opts = {})
    {
      id:,
      is_user_specific: false,
      key:,
      payload: localized_payload,
      text: I18n.t("notification_service.notifications.#{key}.text", **localized_payload),
      title: I18n.t("notification_service.notifications.#{key}.title", **localized_payload),
      link:,
      course_id:,
      course_name: indifferent_payload[:course_name],
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
      expire_at: expire_at&.iso8601,
    }
  end

  def indifferent_payload
    @indifferent_payload ||= payload.with_indifferent_access
  end

  def localized_payload
    @localized_payload ||= indifferent_payload.each_with_object({}) do |(k, v), hash|
      if k.start_with? 'localized_'
        hash[k[10..].to_sym] = locale_string_from JSON.parse(v)
      else
        hash[k.to_sym] = v
      end
    end
  end
end
end
