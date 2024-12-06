# frozen_string_literal: true

# It updates the text search index for a course
class UpdateCourseSearchIndexWorker
  include Sidekiq::Job

  def perform(id)
    Course.find(id).update_search_index
  rescue ActiveRecord::RecordNotFound
    # The course does not exist (anymore), no update is needed.
  end
end
