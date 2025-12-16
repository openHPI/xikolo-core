# frozen_string_literal: true

module CourseService
class ItemGradeDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all

  def as_api_v1(_opts)
    {
      points: dpoints / 10.0,
    }
  end
end
end
