# frozen_string_literal: true

module CourseService
class RichtextDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate :errors

  def fields
    {
      id: object.id,
      text:,
    }
  end

  def as_api_v1(_opts)
    fields.as_json
  end

  def as_event(_opts)
    fields.as_json
  end

  def text
    object.text.external
  end
end
end
