# frozen_string_literal: true

module CourseService
class VisitDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def basic
    {
      id:,
      item_id:,
      user_id:,
      created_at: created_at.iso8601,
      updated_at: updated_at.iso8601,
    }
  end

  def as_api_v1(_opts)
    basic
  end

  def to_event
    basic.merge(
      course_id: item.course_id,
      section_id: item.section.id
    ).merge item_attributes
  end
end
end
