# frozen_string_literal: true

class MailLogStatDecorator < Draper::Decorator
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
