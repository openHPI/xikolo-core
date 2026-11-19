# frozen_string_literal: true

module Global
  class TiltedCard < ApplicationComponent
    def initialize(title:, subtitle: nil, link: nil, color_scheme: 'accent', tilt_direction: 'left')
      @title = title
      @subtitle = subtitle
      @link = link
      @color_scheme = color_scheme
      @tilt_direction = tilt_direction
    end

    private

    def link?
      @link.present?
    end

    def css_classes
      css_classes = @color_scheme.to_s

      css_classes += @tilt_direction == 'right' ? ' rotate-5' : ' -rotate-5'
      css_classes
    end
  end
end
