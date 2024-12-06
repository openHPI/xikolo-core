# frozen_string_literal: true

module Course
  module LearnerDashboard
    module SectionProgress
      class MainPreview < ViewComponent::Preview
        # @!group
        def default
          config =
            {
              'title' => 'Section 1',
              'main_exercises' => {
                'max_points' => 26.0, 'graded_points' => 0.0, 'submitted_points' => 22.0,
                'total_exercises' => 4, 'graded_exercises' => 0, 'submitted_exercises' => 3
              },
              'selftest_exercises' => {
                'max_points' => 4.0, 'graded_points' => 0.0, 'submitted_points' => 4.0,
                'total_exercises' => 2, 'graded_exercises' => 1, 'submitted_exercises' => 2
              },
              'bonus_exercises' =>  {
                'max_points' => 8.0, 'graded_points' => 5.0, 'submitted_points' => 5.0,
                'total_exercises' => 1, 'graded_exercises' => 2, 'submitted_exercises' => 1
              },
              'visits' =>  {'total' => 12, 'user' => 11, 'percentage' => 91},
              'items' =>  [
                {
                  'id' => '19b3bc6b-f2f7-4a52-aab5-e0ce75d78b3f', 'title' => 'Week 1: Quiz 1',
                  'content_type' => 'quiz', 'exercise_type' => 'main', 'user_state' => 'visited',
                  'optional' => false, 'icon_type' => nil, 'max_points' => 10.0, 'user_points' => 10.0
                },
                {
                  'id' => '5c5ace91-1b24-46ea-a8a4-9e1340270437', 'title' => 'Week 1: Quiz 2',
                  'content_type' => 'quiz', 'exercise_type' => 'main', 'user_state' => 'visited',
                  'optional' => false, 'icon_type' => nil, 'max_points' => 7.0, 'user_points' => 5.0
                },
                {
                  'id' => '1916244a-2579-4246-8085-79bede781ec4', 'title' => 'Week 1: Quiz 2.2 (Branch A)',
                  'content_type' => 'quiz', 'exercise_type' => 'main', 'user_state' => 'visited',
                  'optional' => false, 'icon_type' => nil, 'max_points' => 9.0, 'user_points' => 2.0
                },
              ],
            }
          course = ::Course::Course.new(course_code: 'test-123')
          render LearnerDashboard::SectionProgress::Main.new(config, course)
        end

        def empty_state
          config =
            {
              'title' =>  'Section 1',
              'main_exercises' =>  {
                'max_points' => 0.0, 'graded_points' => 0.0, 'submitted_points' => 0.0,
                'total_exercises' => 4, 'graded_exercises' => 0, 'submitted_exercises' => 0
              },
              'selftest_exercises' =>  {
                'max_points' => 0.0, 'graded_points' => 0.0, 'submitted_points' => 0.0,
                'total_exercises' => 2, 'graded_exercises' => 1, 'submitted_exercises' => 0
              },
              'bonus_exercises' =>  {
                'max_points' => 0.0, 'graded_points' => 5.0, 'submitted_points' => 0.0,
                'total_exercises' => 1, 'graded_exercises' => 1, 'submitted_exercises' => 0
              },
              'visits' =>  {'total' => 12, 'user' => 0, 'percentage' => 0},
            }
          course = ::Course::Course.new(course_code: 'test-123')
          render LearnerDashboard::SectionProgress::Main.new(config, course)
        end
        # @!endgroup
      end
    end
  end
end
