# frozen_string_literal: true

module Course
  module LearnerDashboard
    module SectionProgress
      class Main < ApplicationComponent
        include ProgressHelper

        def initialize(section_progress, course)
          @section_progress = section_progress
          @course = course
        end

        def main_statistic
          @section_progress['main_exercises']
        end

        def bonus_statistic
          @section_progress['bonus_exercises']
        end

        def selftest_statistic
          @section_progress['selftest_exercises']
        end

        def items
          # `@section_progress['items']` may be `nil` if the section is not available.
          # Make sure to always return an enumerable object and avoid a tri-state.

          @section_progress['items'].presence || []
        end

        def graded_percentage
          return if main_statistic.blank? || main_statistic['max_points'].zero?

          achieved_points = [
            main_statistic['submitted_points'].presence,
            bonus_statistic&.dig('submitted_points').presence,
          ].compact.sum

          calc_progress(achieved_points, main_statistic['max_points'])
        end

        def selftest_percentage
          return if selftest_statistic.blank? || selftest_statistic['max_points'].zero?

          calc_progress(selftest_statistic['submitted_points'], selftest_statistic['max_points'])
        end

        def completed_items_percentage
          return if completed_items_count.zero? || items_available.zero?

          calc_progress(completed_items_count, items_available)
        end

        def completed_items_count
          items.count {|item| completed_item?(item) }
        end

        def items_available
          @section_progress.dig('visits', 'total').presence || 0
        end

        def legend_items
          [
            {class_modifier: 'completed', text: t(:'course.progress.legend.completed')},
            {class_modifier: 'warning', text: t(:'course.progress.legend.warning')},
            {class_modifier: 'critical', text: t(:'course.progress.legend.critical')},
            {class_modifier: '', text: t(:'course.progress.legend.not_completed')},
            {class_modifier: 'optional', text: t(:'course.progress.legend.optional')},
          ]
        end

        def section_statistics?
          main_statistic.present? || bonus_statistic.present? || selftest_statistic.present?
        end

        private

        def completed_item?(item)
          if gradable_item?(item)
            %w[graded submitted].include?(item['user_state'])
          else
            item['user_state'] == 'visited'
          end
        end

        def gradable_item?(item)
          %w[lti_exercise peer_assessment quiz].include?(item['content_type'])
        end

        def render?
          @section_progress['alternative_state'] != 'parent'
        end
      end
    end
  end
end
