# frozen_string_literal: true

class TestGroupDecorator < ApplicationDecorator
  delegate_all

  def as_json(*)
    {
      id:,
      name:,
      description:,
      flippers:,
      ratio:,
      index:,
      group_id:,
      user_test_id:,
    }.tap do |attrs|
      if context[:statistics]
        attrs.merge!(
          total_count:,
          finished_count:,
          waiting_count:,
          mean:,
          change:,
          control: control?,
          confidence:,
          effect_size: effect,
          required_participants:,
          box_plot_data:
        )
      end
    end
  end
end
