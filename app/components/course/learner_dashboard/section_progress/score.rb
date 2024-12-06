# frozen_string_literal: true

module Course
  module LearnerDashboard
    module SectionProgress
      class Score < ApplicationComponent
        def initialize(label:, value:)
          @label = label
          @value = value
        end

        def css_classes
          disabled? ? 'disabled' : ''
        end

        def disabled?
          @value.nil?
        end
      end
    end
  end
end
