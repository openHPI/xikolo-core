# frozen_string_literal: true

module CourseService
# It updates the text search index for a course
class UpdateCourseSearchIndexWorker # rubocop:disable Layout/IndentationWidth
  include Sidekiq::Job

  def perform(id)
    Course.find(id).update_search_index
  rescue ActiveRecord::RecordNotFound
    # The course does not exist (anymore), no update is needed.
  end
end
end
