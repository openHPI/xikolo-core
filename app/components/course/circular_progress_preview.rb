# frozen_string_literal: true

module Course
  class CircularProgressPreview < ViewComponent::Preview
    # @!group
    # @label
    def optimum
      render ::Course::CircularProgress.new(100, '100%')
    end

    # @label
    def optimal
      render ::Course::CircularProgress.new(90, '90%')
    end

    # @label
    def sub_optimal
      render ::Course::CircularProgress.new(50, '50%')
    end

    # @label
    def sub_sub_optimal
      render ::Course::CircularProgress.new(25, '25%')
    end

    # @label
    def empty
      render ::Course::CircularProgress.new(0, '0%')
    end

    # @!endgroup
    def small
      render ::Course::CircularProgress.new(100, '100%', :small)
    end
  end
end
