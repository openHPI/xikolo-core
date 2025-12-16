# frozen_string_literal: true

module CourseService
class PrerequisiteStatusDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  def as_api_v1(*)
    {
      fulfilled: object.fulfilled?,
      prerequisites:,
    }
  end

  private

  def prerequisites
    object.sets
      .map {|course_status| [course_status, course_status.representative] }
      .sort_by {|_, representative| representative.start_date }
      .map do |course_status, representative|
        {
          course: {
            id: representative.id,
            course_code: representative.course_code,
            title: representative.title,
            visual_url: representative.visual&.image_url,
          },
          fulfilled: course_status.fulfilled?.present?,
          free_reactivation: course_status.free_reactivation?.present?,
          required_certificate: course_status.required_certificate,
          score: course_status.score,
        }
      end
  end
end
end
