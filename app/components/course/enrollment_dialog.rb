# frozen_string_literal: true

module Course
  class EnrollmentDialog < ApplicationComponent
    def initialize(course_identifier, target_id:)
      @course = ::Course::Course.by_identifier(course_identifier).take!
      @target_id = target_id
    end

    def course_title
      @course.title
    end

    def course_code
      @course.course_code
    end

    def enrollment_policy_url
      Translations.new(@course.policy_url).to_s
    end
  end
end
