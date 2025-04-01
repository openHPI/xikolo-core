# frozen_string_literal: true

module Quiz
  class Submission
    class Proctoring
      def initialize(submission)
        @submission = submission
      end

      def results
        @results ||= vendor.results_from_data(@submission['vendor_data'])
      end

      private

      def vendor
        @vendor ||= ::Proctoring::SmowlAdapter.new(course)
      end

      def course
        @course ||= Course::Course.find(@submission['course_id'])
      end
    end
  end
end
