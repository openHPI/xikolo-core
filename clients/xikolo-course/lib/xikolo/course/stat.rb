# frozen_string_literal: true

module Xikolo::Course
  class Stat < Acfs::SingletonResource
    service Xikolo::Course::Client, path: 'stats'

    attribute :user_id, :uuid
    attribute :course_id, :uuid
    attribute :student_enrollments, :integer
    attribute :student_enrollments_by_day, :list
    attribute :student_enrollments_at_start, :integer
    attribute :student_enrollments_at_end, :integer
    attribute :student_enrollments_at_middle, :integer
    attribute :student_enrollments_at_middle_netto, :integer
    attribute :exam_participants, :integer
    attribute :certificates_count, :integer
    attribute :percentile_created_at_days, :list
    attribute :platform_current_enrollments, :integer
    attribute :platform_last_day_enrollments, :integer
    attribute :platform_enrollments, :integer
    attribute :platform_last_day_unique_enrollments, :integer
    attribute :platform_enrollment_delta_sum, :integer
    attribute :platform_custom_completed, :integer
    attribute :platform_total_certificates, :integer
    attribute :shows, :integer
    attribute :no_shows, :integer
    attribute :new_users, :integer
  end
end
