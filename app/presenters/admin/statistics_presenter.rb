# frozen_string_literal: true

class Admin::StatisticsPresenter
  def self.courses
    ::Course::Classifier.find_by(title: 'dashboard', cluster_id: 'reporting')
      &.courses
      &.map {|course| Course.new(course) }
  end

  class Course
    def initialize(course)
      @course = course
    end

    def id
      @course.id
    end

    def course_code
      @course.course_code
    end

    def title
      @course.title
    end

    def formatted_start_date
      I18n.l(@course.start_date, format: :short_datetime)
    end

    def stats
      @course.stats
    end
  end
end
