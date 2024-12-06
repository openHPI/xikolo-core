# frozen_string_literal: true

class StatDecorator < ApplicationDecorator
  delegate_all
  def as_api_v1(_opts)
    {
      course_id:,

      enrollments:,
      enrollments_netto:,
      enrollments_last_day:,
      enrollments_by_day:,
      enrollments_at_start:,
      enrollments_at_start_netto:,
      enrollments_at_middle:,
      enrollments_at_middle_netto:,
      enrollments_at_end:,
      enrollments_at_end_netto:,

      # deprecated
      student_enrollments: enrollments,
      student_enrollments_netto: enrollments_netto,
      student_enrollments_last_day: enrollments_last_day,
      student_enrollments_by_day: enrollments_by_day,
      student_enrollments_at_start: enrollments_at_start,
      student_enrollments_at_start_netto: enrollments_at_start_netto,
      student_enrollments_at_middle: enrollments_at_middle,
      student_enrollments_at_middle_netto: enrollments_at_middle_netto,
      student_enrollments_at_end: enrollments_at_end,
      student_enrollments_at_end_netto: enrollments_at_end_netto,

      percentile_created_at_days:,

      shows:,
      shows_at_start:,
      shows_at_middle:,
      shows_at_end:,
      no_shows:,
      no_shows_at_start:,
      no_shows_at_middle:,
      no_shows_at_end:,

      overall_progress:,

      # global stats
      platform_current_enrollments:,
      platform_last_day_enrollments:,
      platform_enrollments:,
      platform_last_7days_enrollments:,
      platform_last_day_unique_enrollments:,
      platform_enrollment_delta_sum:,
      platform_total_certificates: total_certificates,
      unenrollments:,
      new_users:,
      platform_custom_completed:,
      courses_count: courses,

      # used by global and extended stats
      certificates_count: certificates_count || total_certificates, # deprecated
      quantile_count:,

      # bookings
      proctorings:,
      reactivations:,
    }.compact
  end
end
