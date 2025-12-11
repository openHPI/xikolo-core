# frozen_string_literal: true

module QuizService
module XmlImporter # rubocop:disable Layout/IndentationWidth
  ##
  # Encapsulate interaction with the course service for loading sections and
  # items or creating new (quiz) items respectively.
  class Course
    def initialize(course_id)
      @course_id = course_id
    end

    def course_sections
      @course_sections ||= course_api.rel(:sections).get({course_id: @course_id}).value!
    end

    def alternative_sections(parent_id)
      course_api.rel(:sections).get({course_id: @course_id, parent_id:}).value!
    end

    def find_section(quiz)
      CourseSection.new(self).resolve(quiz)
    end

    def course_item_ids
      @course_item_ids ||= begin
        section_ids = course_sections.pluck('id')

        Restify::Promise.new(section_ids.map do |section_id|
          course_api.rel(:items).get({section_id:}).then do |items|
            items.pluck('content_id')
          end
        end).value!
      end.flatten
    end

    def create_item!(params)
      course_api.rel(:items).post(params).value!
    end

    private

    def course_api
      @course_api ||= Xikolo.api(:course).value!
    end

    class CourseSection
      def initialize(course)
        @course = course
      end

      def resolve(quiz)
        section = @course.course_sections[quiz['section'].to_i - 1]

        if quiz['subsection'].to_i.positive?
          alternative_sections = @course.alternative_sections(section['id'])
          section = alternative_sections[quiz['subsection'].to_i - 1]
        end

        section
      end
    end
  end
end
end
