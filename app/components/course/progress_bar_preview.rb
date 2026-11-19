# frozen_string_literal: true

module Course
  class ProgressBarPreview < ViewComponent::Preview
    # @!group

    # @param percentage number
    def default(percentage: 10)
      render ::Course::ProgressBar.new(percentage:)
    end

    def loading
      render ::Course::ProgressBar.new
    end

    # @!endgroup
  end
end
