# frozen_string_literal: true

module CourseService
class TeacherDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate :errors

  def as_api_v1(*)
    {
      id: model.id,
      name: model.name,
      description: model.description,
      picture_url: model.picture_url,
    }
  end
end
end
