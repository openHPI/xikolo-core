# frozen_string_literal: true

module CourseService
  class PurgeDeletedCoursesJob < ApplicationJob
    queue_as :default

    BATCH_SIZE = 10

    def perform
      Course.deleted_for_purge.find_each(batch_size: BATCH_SIZE) do |course|
        Course::Purge.call(course)
      end
    end
  end
end
