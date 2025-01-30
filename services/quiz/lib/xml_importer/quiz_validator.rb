# frozen_string_literal: true

module XMLImporter
  ##
  # Handle domain-specific quiz XML validation logic:
  # Validate quizzes for required parameters and existing course sections.
  class QuizValidator
    def initialize(course, course_code)
      @course = course
      @course_code = course_code
    end

    def validate!(quizzes)
      errors = []
      quizzes.each do |quiz_hash|
        errors << validate_section(quiz_hash)
        errors << validate_course(quiz_hash)
      end
      errors.compact!

      raise ::XMLImporter::ParameterError.new(errors) if errors.any?
    end

    private

    def validate_section(quiz_hash)
      section = @course.find_section(quiz_hash)
      "Course section for quiz '#{quiz_hash['name']}' does not exist" if section.nil?
    end

    def validate_course(quiz_hash)
      if quiz_hash['course_code'] != @course_code
        "Quiz '#{quiz_hash['name']}' has an incorrect course code"
      end
    end
  end
end
