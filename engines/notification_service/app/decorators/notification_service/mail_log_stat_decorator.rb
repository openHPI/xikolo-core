# frozen_string_literal: true

module NotificationService
class MailLogStatDecorator < Draper::Decorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_json(_opts = {})
    {
      news_id:,
      count:,
      success_count:,
      error_count:,
      disabled_count:,
      unique_count:,
      oldest: oldest&.iso8601,
      newest: newest&.iso8601,
    }
  end
end
end
