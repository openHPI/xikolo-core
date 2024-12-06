# frozen_string_literal: true

module Metrics
  class EnrollmentsMetric < Metric
    def self.query(user_id, course_id, start_date, _end_date)
      enrollment = Xikolo.api(:course).value!.rel(:enrollments).get(
        user_id:,
        course_id:
      ).value!.first

      if enrollment && DateTime.parse(enrollment['created_at']) > start_date
        1
      else
        0
      end
    end

    def set_distribution
      self.distribution ||= :binomial
    end

    def set_name
      self.name ||= 'Enrollments'
    end
  end
end
