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
                'max_points' => 30.0, 'graded_points' => 30.0, 'submitted_points' => 18.0,
                'total_exercises' => 5, 'graded_exercises' => 4, 'submitted_exercises' => 1
              },
              'selftest_exercises' => {
                'max_points' => 1.0, 'graded_points' => 0.0, 'submitted_points' => 1.0,
                'total_exercises' => 1, 'graded_exercises' => 0, 'submitted_exercises' => 1
              },
              'bonus_exercises' =>  {
                'max_points' => 2.0, 'graded_points' => 2.0, 'submitted_points' => 1.0,
                'total_exercises' => 1, 'graded_exercises' => 2, 'submitted_exercises' => 1
              },
              'visits' =>  {'total' => 6, 'user' => 2, 'percentage' => 66},
              'items' =>  [
                {
                  'id' => '19b3bc6b-f2f7-4a52-aab5-e0ce75d78b3f', 'title' => 'Week 1: Welcome video',
                  'content_type' => 'video', 'exercise_type' => 'nil', 'user_state' => 'visited',
                  'optional' => false, 'icon_type' => nil, 'max_points' => 0
                },
                {
                  'id' => '5c5ace91-1b24-46ea-a8a4-9e1340270437', 'title' => 'Week 1: Quiz 1',
                  'content_type' => 'quiz', 'exercise_type' => 'main', 'user_state' => 'graded',
                  'optional' => false, 'icon_type' => nil, 'max_points' => 10.0, 'user_points' => 5.0
                },
                {
                  'id' => '1916244a-2579-4246-8085-79bede781ec4', 'title' => 'Week 1: Quiz 2',
                  'content_type' => 'quiz', 'exercise_type' => 'main', 'user_state' => 'graded',
                  'optional' => false, 'icon_type' => nil, 'max_points' => 10.0, 'user_points' => 4.0
                },
                {
                  'id' => '1916244a-2579-4246-8085-79bede781ec5', 'title' => 'Week 1: Quiz 3',
                  'content_type' => 'quiz', 'exercise_type' => 'main', 'user_state' => 'graded',
                  'optional' => false, 'icon_type' => nil, 'max_points' => 10.0, 'user_points' => 9.0
                },
                {
                  'id' => '5c5ace91-1b24-46ea-a8a4-9e1340270437', 'title' => 'Week 1: Bonus Quiz',
                  'content_type' => 'quiz', 'exercise_type' => 'bonus', 'user_state' => 'graded',
                  'optional' => false, 'icon_type' => nil, 'max_points' => 2.0, 'user_points' => 1.0
                },
                {
                  'id' => '5c5ace91-1b24-46ea-a8a4-9e1340270437', 'title' => 'Week 1: Selftest',
                  'content_type' => 'quiz', 'exercise_type' => 'selftest', 'user_state' => 'submitted',
                  'optional' => false, 'icon_type' => nil, 'max_points' => 1.0, 'user_points' => 1.0
                },
                {
                  'id' => '1916244a-2579-4246-8085-79bede781ec3', 'title' => 'Week 1: Text (Optional)',
                  'content_type' => 'rich_text', 'exercise_type' => 'nil', 'user_state' => 'new',
                  'optional' => true, 'icon_type' => nil, 'max_points' => 9.0, 'user_points' => 2.0
                },
              ],
            }
          course = ::Course::Course.new(course_code: 'test-123')
          render LearnerDashboard::SectionProgress::Main.new(config, course)
        end

        def empty_state
          config =
            {
              'title' =>  'Section 2',
              'main_exercises' =>  nil,
              'selftest_exercises' =>  nil,
              'bonus_exercises' =>  nil,
              'visits' =>  {'total' => 0, 'user' => 0, 'percentage' => 0},
            }
          course = ::Course::Course.new(course_code: 'test-123')
          render LearnerDashboard::SectionProgress::Main.new(config, course)
        end
        # @!endgroup
      end
    end
  end
end
