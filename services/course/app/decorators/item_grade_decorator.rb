# frozen_string_literal: true

class ItemGradeDecorator < ApplicationDecorator
  delegate_all

  def as_api_v1(_opts)
    {
      points: dpoints / 10.0,
    }
  end
end
