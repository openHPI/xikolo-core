# frozen_string_literal: true

module Course
  module LearnerDashboard
    class CourseProgress < ApplicationComponent
      include ProgressHelper
      include ActiveSupport::NumberHelper

      EMPTY_STATE = '—'

      def initialize(progresses, course)
        @course_progress = progresses.pop
        @section_progresses = progresses
        @course = course
      end

      def graded_score
        return if @course_progress['main_exercises'].blank? &&
                  @course_progress['bonus_exercises'].blank?

        achieved_points = [
          @course_progress.dig('main_exercises', :submitted_points).presence,
          @course_progress.dig('bonus_exercises', :submitted_points).presence,
        ].compact.sum
        available_points = @course_progress.dig('main_exercises', :max_points)

        return unless available_points&.positive?

        achieved = number_to_rounded(achieved_points, strip_insignificant_zeros: true)
        available = number_to_rounded(available_points, strip_insignificant_zeros: true)
        t(:'course.progress.graded', achieved:, available:)
      end

      def selftest_score
        return if @course_progress['selftest_exercises'].blank?

        achieved_points = @course_progress.dig('selftest_exercises', :submitted_points)
        available_points = @course_progress.dig('selftest_exercises', :max_points)

        return unless available_points&.positive?

        achieved = number_to_rounded(achieved_points, strip_insignificant_zeros: true)
        available = number_to_rounded(available_points, strip_insignificant_zeros: true)
        t(:'course.progress.selftest', achieved:, available:)
      end

      def items_visited
        @course_progress.dig('visits', :user).presence || 0
      end

      def items_available
        @course_progress.dig('visits', :total).presence || 0
      end

      def graded_percentage
        @graded_percentage ||= begin
          achieved_points = [
            @course_progress.dig('main_exercises', :submitted_points).presence,
            @course_progress.dig('bonus_exercises', :submitted_points).presence,
          ].compact.sum
          available_points = @course_progress.dig('main_exercises', :max_points)

          calc_progress(achieved_points, available_points)
        end
      end

      def selftest_percentage
        @selftest_percentage ||= begin
          achieved_points = @course_progress.dig('selftest_exercises', :submitted_points)
          available_points = @course_progress.dig('selftest_exercises', :max_points)

          calc_progress(achieved_points, available_points)
        end
      end

      def visits_percentage
        @visits_percentage ||= calc_progress(items_visited, items_available)
      end
    end
  end
end
