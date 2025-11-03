# frozen_string_literal: true

module TimeeffortService
class ItemDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all
  def fields
    {
      id:,
      content_type:,
      content_id:,
      section_id:,
      course_id:,
      time_effort:,
      calculated_time_effort:,
      time_effort_overwritten:,
    }.tap do |attrs|
      attrs[:overwritten_time_effort_url] = h.item_overwritten_time_effort_url(item_id: id)
    end
  end

  def as_json(_opts)
    fields
  end
end
end
