# frozen_string_literal: true

module CourseService
class NextDateDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate :errors

  def as_api_v1(_opts)
    {
      course_id: model.course_id,
      course_code: model.course.course_code,
      course_title: model.course.title,
      resource_type: model.resource_type,
      resource_id: model.resource_id,
      type: model.type,
      title: model.title,
      date: model.date.iso8601(3),
    }
  end
end
end
