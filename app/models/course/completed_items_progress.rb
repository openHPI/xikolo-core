# frozen_string_literal: true

module Course
  class CompletedItemsProgress
    # @param course [CourseService::Course]
    def initialize(course, user_id)
      *@section_progresses, @course_progress = CourseService::Progresses.new(course, user_id).to_a
    end

    def total
      @total ||= @course_progress.visited_total
    end

    def completed
      @completed ||= @section_progresses.sum do |progress|
        next 0 if progress.child_section? && !progress.best_alternative?
        next 0 unless progress.available_section?

        progress.items.count do |item|
          !item.optional? &&
            CourseService::Item.completed?(
              content_type: item.content_type_name,
              user_state: item.user_state,
              max_points: item.max_dpoints,
              exercise_type: item.exercise_type
            )
        end
      end
    end

    def percentage
      return 0 if total.zero?

      [completed.fdiv(total) * 100, 100].min.floor
    end
  end
end
