# frozen_string_literal: true

class MetricDecorator < ApplicationDecorator
  delegate_all

  def as_json(*)
    {
      id:,
      name:,
      wait:,
      wait_interval:,
      type:,
      distribution:,
    }.as_json
  end
end
