# frozen_string_literal: true

# Monitors courses for changes in their course language
# and rebuild the search index for all questions of this course.
#
class PinboardSearchCourseConsumer < Msgr::Consumer
  def update
    course_id = payload.fetch(:id)
    language = payload.fetch(:lang)

    # Remove cached course record
    Course.delete(course_id)

    # Schedule update for all records with miss-matched language
    Question
      .where(course_id:)
      .where.not(language:)
      .schedule_search_text_update
  end
end
