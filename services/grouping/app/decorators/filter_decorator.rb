# frozen_string_literal: true

class FilterDecorator < ApplicationDecorator
  delegate_all

  def as_json(*)
    {
      id:,
      field_name:,
      field_value:,
      operator:,
    }.as_json
  end
end
