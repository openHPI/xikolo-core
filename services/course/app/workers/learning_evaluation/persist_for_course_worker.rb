# frozen_string_literal: true

module LearningEvaluation
  class PersistForCourseWorker
    include Sidekiq::Job

    def perform(course = nil, enqueued_at = Time.zone.now.to_s)
      if course.nil?
        # Save some round trips to Redis when queuing jobs for all courses
        # by calling `perform_bulk` directly.
        Course.unscope(:order).in_batches do |courses|
          now = Time.zone.now.to_s
          job_args = courses.ids.map {|x| [x, now] }
          self.class.perform_bulk(job_args)
        end
      else
        @course = Course.by_identifier(course).take!
        @enqueued_at = DateTime.parse(enqueued_at)

        create_progresses!
        @course.mark_recalculated!
      end
    end

    private

    def create_progresses!
      sections = @course.sections

      # Retrieve all course enrollments to access the user IDs.
      @course.enrollments.unscope(:order).find_each(batch_size: 50) do |enrollment|
        releasing_resources do
          # For each user, create / update the section progresses for this course.
          sections.each do |section|
            # If a section doesn't have any item, go for the next section.
            next if section.items.count.zero?

            # Create / calculate the progress for all users for this section.
            # Do NOT update a section progress again, which has already been
            # updated since this worker has been scheduled. Also, skip the
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
