# frozen_string_literal: true

module Quiz
  class Submission
    class Proctoring
      def initialize(submission)
        @submission = submission
      end

      def vendor_cam_url
        vendor.cam_url(
          @submission,
          redirect_to: Rails.application.routes.url_helpers.course_url(
            course,
            host: Xikolo.config.base_url.site
          )
        )
      end

      def results
        @results ||= vendor.results_from_data(@submission['vendor_data'])
      end

      def loaded?
        @submission.dig('vendor_data', 'proctoring_smowl_v2').present?
      end

      def load_from_vendor!
        results = vendor.submission_results(@submission)

        raise VendorNotReady.new if results.empty?

        update!({
          vendor_data: @submission['vendor_data'].merge(
            # Only store the bad things not the good ones!
            'proctoring_smowl_v2' => results.except('correctuser')
          ),
        })
      end

      def exclude!
        vendor.exclude_from_proctoring!(@submission)
      end

      private

      def update!(attrs)
        Xikolo.api(:quiz).value!.rel(:quiz_submission).patch(
          attrs,
          {id: @submission['id']}
        ).value!
      end

      def vendor
        @vendor ||= ::Proctoring::SmowlAdapter.new(course)
      end

      def course
        @course ||= Course::Course.find(@submission['course_id'])
      end

      class VendorNotReady < RuntimeError; end
    end
  end
end
