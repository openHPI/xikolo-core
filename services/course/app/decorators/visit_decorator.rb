# frozen_string_literal: true

class VisitDecorator < ApplicationDecorator
  delegate_all

  def basic
    {
      id:,
      item_id:,
      user_id:,
      created_at:,
      updated_at:,
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
