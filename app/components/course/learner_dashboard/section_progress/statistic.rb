# frozen_string_literal: true

module Course
  module LearnerDashboard
    module SectionProgress
      class Statistic < ApplicationComponent
        include ProgressHelper
        include ActiveSupport::NumberHelper

        def initialize(label:, values:, icon:)
          @label = label
          @values = values
          @icon = icon
        end

        def percentage
          return unless @values&.dig('max_points')&.positive?

          calc_progress(@values['submitted_points'], @values['max_points'])
        end

        def points_scored
          return unless @values&.dig('max_points')&.positive?

          max_points = number_to_rounded(@values['max_points'], strip_insignificant_zeros: true)
          submitted_points = number_to_rounded(@values['submitted_points'], strip_insignificant_zeros: true)

          t(:'course.progress.statistics.points_achieved', submitted_points:, max_points:)
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
