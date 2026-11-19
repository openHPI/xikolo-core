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

          Restify::Promise.new(
            course_api.rel(:stats).get({course_id:, key: 'enrollments'}),
            course_api.rel(:stats).get({course_id:, key: 'shows_and_no_shows'})
          ) do |enrollments, shows|
            build_result(
              enrollments || {},
              shows || {}
            )
          end.value! || {}
        end

        private

        attr_reader :course_id

        def build_result(enrollments, shows)
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
              Certificate::Record.where(course_id: @course_id).group(:type).count,
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

        def build_certificates(certificates, shows)
          certificates ||= {}

          {
            roa_count: certificates.fetch('RecordOfAchievement', 0),
            cop_count: certificates.fetch('ConfirmationOfParticipation', 0),
            completion_rate: percent(
              certificates['RecordOfAchievement'],
              shows['shows_at_middle']
            ),
            consumption_rate_current: percent(
              certificates['ConfirmationOfParticipation'],
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
