# frozen_string_literal: true

module Course
  module LearnerDashboard
    module SectionProgress
      class Statistic < ApplicationComponent
        include ProgressHelper

        def initialize(label:, values:, icon:)
          @label = label
          @values = values
          @icon = icon
        end

        def points_scored
          return unless @values&.dig('max_points')&.positive?

          percentage = calc_progress(@values['submitted_points'], @values['max_points'])
          "#{@values['submitted_points']} / #{@values['max_points']} (#{percentage}%)"
        end

        def exercises_taken
          return if @values.blank?
          return unless @values['total_exercises']&.positive?

          t(:'course.progress.statistics.items_taken',
            taken: @values['submitted_exercises'],
            total: @values['total_exercises'])
        end

        private

        def render?
          @values.present?
        end
      end
    end
  end
end
