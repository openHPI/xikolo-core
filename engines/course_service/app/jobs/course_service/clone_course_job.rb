# frozen_string_literal: true

module CourseService
  class CloneCourseJob < ApplicationJob
    queue_as :default

    def perform(payload)
      return unless payload &&
                    payload[:old_course_id] &&
                    payload[:new_course_code]

      Course::Clone.call(
        payload[:old_course_id],
        payload[:new_course_code]
      )
    end
  end
end
