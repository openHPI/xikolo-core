# frozen_string_literal: true

class SectionDecorator < ApplicationDecorator
  delegate_all
  def as_api_v1(_opts)
    {
      id:,
      course_id:,
      title:,
      description:,
      published:,
      start_date: start_date.try(:iso8601, 3),
      end_date: end_date.try(:iso8601, 3),
      position:,
      optional_section:,
      effective_start_date: model.effective_start_date.try(:iso8601, 3),
      effective_end_date: model.effective_end_date.try(:iso8601, 3),
      course_archived: model.course_archived,
      pinboard_closed:,
      alternative_state:,
      parent_id:,
      required_section_ids:,
    }
  end
end
