# frozen_string_literal: true

module Admin
  module Statistics
    module Course
      class KpiCards < ApplicationOperation
        include MetricHelpers

        def initialize(course_id:)
          super()

          @course_id = course_id
        end

        def call
          return {} if course_id.blank?

          course = course_api.rel(:course).get({id: course_id}).value!

          Restify::Promise.new(
            course_api.rel(:stats).get({course_id:, key: 'enrollments'}),
            course_api.rel(:stats).get({course_id:, key: 'shows_and_no_shows'}),
            fetch_metric(name: 'certificates', course_id:),
            fetch_metric(
              name: 'certificates',
              course_id:,
              start_date: course['start_date'],
              end_date: course['end_date']
            ),
            fetch_metric(
              name: 'certificates',
              course_id:,
              start_date: course['end_date']
            )
          ) do |enrollments, shows, certificates, certificates_at_end, certificates_after_end|
            build_result(
              enrollments || {},
              shows || {},
              certificates,
              certificates_at_end,
              certificates_after_end
            )
          end.value! || {}
        end

        private

        attr_reader :course_id

        def build_result(enrollments, shows, certificates, certificates_at_end, certificates_after_end)
          {
            enrollments: {
              total: enrollments['enrollments'],
              total_netto: enrollments['enrollments_netto'],
              last_day: enrollments['enrollments_last_day'],
              at_start: enrollments['enrollments_at_start'],
              at_start_netto: enrollments['enrollments_at_start_netto'],
              at_middle: enrollments['enrollments_at_middle'],
              at_middle_netto: enrollments['enrollments_at_middle_netto'],
              at_end: enrollments['enrollments_at_end'],
              at_end_netto: enrollments['enrollments_at_end_netto'],
            },
            activity: build_activity(enrollments, shows),
            certificates: build_certificates(
              certificates,
              certificates_at_end,
              certificates_after_end,
              shows
            ),
          }
        end

        def build_activity(enrollments, shows)
          {
            shows: shows['shows'],
            shows_at_middle: shows['shows_at_middle'],
            shows_at_end: shows['shows_at_end'],
            show_quota: percent(shows['shows'], enrollments['enrollments']),
            show_quota_at_middle: percent(
              shows['shows_at_middle'],
              enrollments['enrollments_at_middle']
            ),
            show_quota_at_end: percent(
              shows['shows_at_end'],
              enrollments['enrollments_at_end']
            ),
          }
        end

        def build_certificates(certificates, certificates_at_end, certificates_after_end, shows)
          certificates ||= {}

          cop_at_end = certificates_at_end&.dig('confirmation_of_participation')
          cop_after_end = certificates_after_end&.dig('confirmation_of_participation')

          {
            roa_count: certificates['record_of_achievement'],
            cop_count: certificates['confirmation_of_participation'],
            qc_count: certificates['qualified_certificate'],
            cop_at_end_count: cop_at_end,
            cop_after_end_count: cop_after_end,
            completion_rate: percent(
              certificates['record_of_achievement'],
              shows['shows_at_middle']
            ),
            consumption_rate_at_end: percent(
              cop_at_end,
              shows['shows_at_end']
            ),
            consumption_rate_after_end: percent(
              cop_after_end,
              shows['shows'].to_i - shows['shows_at_end'].to_i
            ),
            consumption_rate_current: percent(
              certificates['confirmation_of_participation'],
              shows['shows']
            ),
          }
        end

        def percent(number, total)
          total_int = total.to_i
          return 0 if total_int.zero?

          number.to_i * 100 / total_int
        end
      end
    end
  end
end
