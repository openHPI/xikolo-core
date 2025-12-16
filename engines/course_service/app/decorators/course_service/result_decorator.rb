# frozen_string_literal: true

module CourseService
class ResultDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def basic
    {
      id:,
      user_id:,
      item_id:,
      points: dpoints / 10.0,
    }
  end

  def as_api_v1(_opts)
    basic
  end

  def to_event
    basic.merge!(
      course_id: model.item.section.course_id,
      section_id: model.item.section.id,
      created_at:,
      updated_at:
    ).merge item_attributes
  end
end
end
