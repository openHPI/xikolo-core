# frozen_string_literal: true

module Transpipe
  class << self
    def enabled?
      Xikolo.config.transpipe&.dig('enabled')
    end
  end

  class URL
    require 'addressable/template'

    class << self
      def for_course(course)
        course_url_template&.expand(
          course_id: course.try(:[], 'id') || course.id
        )&.to_s
      end

      def course_url_template
        return unless Xikolo.config.transpipe['course_url_template']

        Addressable::Template.new(
          Xikolo.config.transpipe['course_url_template']
        )
      rescue TypeError
        # The template cannot be parsed for whatever reason.
        # This is fine.
      end

      def for_video(item)
        course_video_url_template&.expand(
          course_id: item.try(:[], 'course_id') || item.course_id,
          video_id: item.try(:[], 'content_id') || item.content_id
        )&.to_s
      end

      def course_video_url_template
        return unless Xikolo.config.transpipe['course_video_url_template']

        Addressable::Template.new(
          Xikolo.config.transpipe['course_video_url_template']
        )
      rescue TypeError
        # The template cannot be parsed for whatever reason.
        # This is fine.
      end
    end
  end
end
