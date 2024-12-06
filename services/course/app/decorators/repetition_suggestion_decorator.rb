# frozen_string_literal: true

class RepetitionSuggestionDecorator < ApplicationDecorator
  delegate_all

  def fields
    {
      id: object.id,
      course_id: object.course_id,
      section_id: object.section_id,
      title: object.title,
      content_type: object.content_type,
      exercise_type: object.exercise_type,
      user_points: object.user_dpoints.try(:/, 10.0),
      max_points: object.max_dpoints.try(:/, 10.0),
      points_percentage: object.percentage.floor,
    }
  end

  def as_api_v1(_opts)
    fields
  end

  def as_event(_opts = {})
    fields.as_json
  end
end
