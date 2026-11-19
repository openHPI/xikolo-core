# frozen_string_literal: true

module CourseReactivation
  class << self
    def config(key)
      Xikolo.config.course_reactivation[key]
    end
  end
end
