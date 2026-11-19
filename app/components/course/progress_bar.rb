# frozen_string_literal: true

module Course
  class ProgressBar < ApplicationComponent
    # Without a percentage, renders a loading skeleton
    def initialize(percentage: nil)
      @percentage = percentage
    end

    def loading?
      @percentage.nil?
    end
  end
end
