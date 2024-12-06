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
          if @values&.dig('max_points')&.positive?
            percentage = calc_progress(@values['submitted_points'], @values['max_points'])
            "#{@values['submitted_points']} / #{@values['max_points']} (#{percentage}%)"
          else
            '-'
          end
        end

        def exercises_taken
          return if @values.blank?

          if @values['total_exercises']&.positive?
            t(:'course.progress.statistics.items_taken',
              taken: @values['submitted_exercises'],
              total: @values['total_exercises'])
          end
        end
      end
    end
  end
end
