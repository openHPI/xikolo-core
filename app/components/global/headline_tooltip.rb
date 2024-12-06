# frozen_string_literal: true

module Global
  class HeadlineTooltip < ApplicationComponent
    def initialize(headline, tooltip = nil, level:)
      @headline = headline
      @tooltip = tooltip
      @level = level
    end
  end
end
