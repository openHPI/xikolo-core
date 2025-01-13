# frozen_string_literal: true

module Global
  class MeterPreview < ViewComponent::Preview
    # @!group
    def default
      render Global::Meter.new(value: 50)
    end

    def low_value
      render Global::Meter.new(value: 25)
    end

    def high_value
      render Global::Meter.new(value: 100)
    end

    def type_info
      render Global::Meter.new(value: 50, type: :info)
    end

    # Per default, the meter fills the width of a container.
    # To make it fill a specific space, you need to set the width of the container.
    def custom_width
      render_with_template
    end

    def with_label
      render Global::Meter.new(value: 40, label: '40%')
    end

    def white_background
      render Global::Meter.new(value: 40, background_color: :white)
    end
    # @!endgroup
  end
end
