# frozen_string_literal: true

module CourseService
module LearningEvaluation # rubocop:disable Layout/IndentationWidth
  class PersistForCourseJob < ApplicationJob
    queue_as :default

    def perform(course, enqueued_at = Time.zone.now.to_s)
      @course = Course.by_identifier(course).take!
      @enqueued_at = DateTime.parse(enqueued_at)

      create_progresses!
      @course.mark_recalculated!
    end

    private

    def create_progresses!
      sections = @course.sections

      # Retrieve all course enrollments to access the user IDs.
      @course.enrollments.find_each(batch_size: 50) do |enrollment|
        releasing_resources do
          # For each user, create / update the section progresses for this course.
          sections.each do |section|
            # If a section doesn't have any item, go for the next section.
            next if section.items.none?

            # Create / calculate the progress for all users for this section.
            # Do NOT update a section progress again, which has already been
            # updated since this job has been scheduled. Also, skip the
            # course progress creation as this would cause redundant updates.
            # The course progress is calculated in the end once all section
            # progresses for this course have been created.
            SectionProgress::Calculate.call(
              section.id,
              enrollment.user_id,
              stale_at: @enqueued_at,
              update_course_progress: false
            )
          end

          # Create / update the course progress for the user since all section
          # progresses have been created / updated.
          CourseProgress::Calculate.call(@course.id, enrollment.user_id)
        end
      end
    end

    def releasing_resources
      yield

      # Empty ActiveRecord's query cache.
      # Without this, the cache may become a huge memory leak, as this job
      # can run for a very long time, e.g. when looping over all enrollments
      # of a very large course.
      ActiveRecord::Base.connection.clear_query_cache

      # Give other threads (e.g. Sidekiq's heartbeat thread) a chance to run.
      ::Thread.pass
    end
  end
end
end
