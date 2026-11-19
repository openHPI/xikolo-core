# frozen_string_literal: true

module Course
  module LearnerProgress
    class SectionsPreview < ViewComponent::Preview
      # Continues at the last visited item, whose section is opened.
      # The learner completed all items of the first section. The third section
      # is locked until its start date.
      # The final exam section is locked until the learner reached the required
      # course progress.
      # @label Course in progress
      def in_progress
        render ::Course::LearnerProgress::Sections.new(progresses, course, current_item_id: item_id(4),
          locked_item_ids: [item_id(9)], exam_unlock_percentage: 70)
      end

      # The learner failed the final exam and can retake it.
      # @label Exam failed
      def exam_failed
        failed_exam = item(9, 'Final exam', 'quiz', exercise_type: 'exam', user_state: 'graded',
          max_points: 20.0, user_points: 8.0, pass_percentage: 70)
        render ::Course::LearnerProgress::Sections.new(progresses(final_exam: failed_exam), course,
          current_item_id: item_id(4), retakable_item_ids: [item_id(9)])
      end

      # Starts with the first item before visiting any.
      # @label Course not started
      def not_started
        render ::Course::LearnerProgress::Sections.new(not_started_progresses, course,
          current_item_id: item_id(1))
      end

      private

      def course
        ::CourseService::Course.new(course_code: 'digital-justice')
      end

      def progresses(final_exam: item(9, 'Final exam', 'quiz', exercise_type: 'exam', max_points: 20.0))
        [
          section(1, 'Week 1: Welcome', [
            item(1, '1.1. Welcome to the course', 'video', user_state: 'visited'),
            item(2, '1.2. How does bias get into AI systems?', 'rich_text', user_state: 'visited'),
            item(3, '1.3. Self-test', 'quiz', exercise_type: 'selftest', user_state: 'submitted',
              max_points: 3.0, user_points: 3.0),
          ]),
          section(2, 'Week 2: Fairness', [
            item(4, '2.1. Measuring fairness', 'video', user_state: 'visited'),
            item(5, '2.2. Graded quiz', 'quiz', exercise_type: 'main', user_state: 'graded',
              max_points: 10.0, user_points: 3.0),
            item(6, '2.3. Further reading', 'rich_text'),
          ]),
          # Before its start date: the progress lists no items.
          section(3, 'Week 3: Outlook', nil, available: false),
          # Exams do not count towards the progress.
          section(4, 'Final exam', [final_exam]),
          {'kind' => 'course'},
        ]
      end

      def not_started_progresses
        [
          section(1, 'Week 1: Welcome', [
            item(1, '1.1. Welcome to the course', 'video'),
            item(2, '1.2. How does bias get into AI systems?', 'rich_text'),
          ]),
          section(2, 'Week 2: Fairness', [
            item(4, '2.1. Measuring fairness', 'video'),
          ]),
          {'kind' => 'course'},
        ]
      end

      def item_id(number)
        format('00000003-3100-4444-9999-%012d', number)
      end

      def section(number, title, items, available: true)
        {
          'kind' => 'section',
          'resource_id' => format('00000002-3100-4444-9999-%012d', number),
          'title' => title,
          'alternative_state' => 'none',
          'available' => available,
          'items' => items,
        }
      end

      def item(number, title, content_type, exercise_type: nil, user_state: 'new', max_points: nil, user_points: nil,
               pass_percentage: nil)
        {
          'id' => item_id(number),
          'title' => title,
          'content_type' => content_type,
          'exercise_type' => exercise_type,
          'user_state' => user_state,
          'max_points' => max_points,
          'user_points' => user_points,
          'pass_percentage' => pass_percentage,
        }
      end
    end
  end
end
