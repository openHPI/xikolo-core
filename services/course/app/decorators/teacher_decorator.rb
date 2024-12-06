# frozen_string_literal: true

class TeacherDecorator < ApplicationDecorator
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
