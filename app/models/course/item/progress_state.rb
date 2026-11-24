# frozen_string_literal: true

module Course
  module Item
    # Whether the learner is done with an item, to mark it as such:
    #
    # - exams once submitted with at least their pass percentage
    # - gradable items (quizzes, LTI exercises, cmi5 with points) once
    #   submitted with at least half of the points, or without points to
    #   achieve, or once their submission deadline passed
    # - surveys once submitted
    # - any other item once visited
    #
    class ProgressState
      include ProgressHelper

      # rubocop:disable-next Metrics/ParameterLists
      def initialize(content_type:, exercise_type:, user_state:, user_points:,
                     max_points:, deadline_passed: false, pass_percentage: nil)
        @content_type = content_type
        @exercise_type = exercise_type
        @user_state = user_state
        @user_points = user_points
        @max_points = max_points
        @deadline_passed = deadline_passed
        @pass_percentage = pass_percentage
      end

      def marked?
        case @content_type
          when 'QuizService::Quiz'
            quiz_marked?
          when 'Lti::Exercise'
            gradable_marked?
          when 'Cmi5::Item'
            scored_cmi5? ? gradable_marked? : @user_state == 'visited'
          else
            @user_state == 'visited'
        end
      end

      # Whether the learner failed an exam: submitted below its pass percentage.
      def failed?
        @content_type == 'QuizService::Quiz' && exam? && submitted? && !exam_passed?
      end

      private

      def quiz_marked?
        if exam?
          exam_passed?
        elsif survey?
          submitted?
        else
          gradable_marked?
        end
      end

      def exam?
        @exercise_type == 'exam'
      end

      def survey?
        @exercise_type == 'survey'
      end

      def scored_cmi5?
        @max_points.to_f.positive?
      end

      def submitted?
        %w[graded submitted].include?(@user_state)
      end

      # Exams have a binary outcome: passed at or above their pass percentage, or failed.
      def exam_passed?
        submitted? && percentage >= @pass_percentage.to_f
      end

      def gradable_marked?
        return false unless submitted?
        return true if @deadline_passed || @max_points.nil? || @max_points.zero?

        percentage >= 50
      end

      def percentage
        calc_progress(@user_points, @max_points)
      end
    end
  end
end
