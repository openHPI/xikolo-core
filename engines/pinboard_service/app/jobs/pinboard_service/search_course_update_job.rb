# frozen_string_literal: true

module PinboardService
class SearchCourseUpdateJob < ApplicationJob # rubocop:disable Layout/IndentationWidth
  queue_as :default

  def perform(payload)
    course_id = payload.fetch('id')
    language = payload.fetch('lang')

    # Remove cached course record
    Course.delete(course_id)

    # Schedule update for all records with miss-matched language
    Question
      .where(course_id:)
      .where.not(language:)
      .schedule_search_text_update
  end
end
end
