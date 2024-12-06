# frozen_string_literal: true

class CalendarEventDecorator < Draper::Decorator
  delegate_all

  def as_json(_opts = {})
    {
      id:,
      collab_space_id:,
      title:,
      description:,
      start_time:,
      end_time:,
      category:,
      user_id:,
      all_day:,
    }
  end
end
