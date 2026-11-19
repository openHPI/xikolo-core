# frozen_string_literal: true

module Course
  class QuizRecap < ApplicationComponent
    def initialize(course_id)
      @url = "app/quiz-recap/?course_id=#{course_id}"
    end
  end
end
