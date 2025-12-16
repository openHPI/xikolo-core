# frozen_string_literal: true

module CourseService
class SectionDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all
  def as_api_v1(_opts)
    {
      id:,
      course_id:,
      title:,
      description:,
      published:,
      start_date: start_date&.iso8601,
      end_date: end_date&.iso8601,
      position:,
      optional_section:,
      effective_start_date: model.effective_start_date&.iso8601,
      effective_end_date: model.effective_end_date&.iso8601,
      course_archived: model.course_archived,
      pinboard_closed:,
      alternative_state:,
      parent_id:,
      required_section_ids:,
    }
  end
end
end
