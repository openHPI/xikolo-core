# frozen_string_literal: true

module Xikolo::Course
  class Enrollment < Acfs::Resource
    service Xikolo::Course::Client, path: 'enrollments'

    attribute :id, :uuid
    attribute :user_id, :uuid
    attribute :course_id, :uuid
    attribute :created_at, :date_time
    attribute :completed, :boolean
    attribute :completed_at, :date_time
    attribute :points, :dict
    attribute :quantile, :float
    attribute :certificates, :dict
    attribute :visits, :dict
    attribute :proctored, :boolean
    attribute :last_visit, :date_time
    attribute :deleted, :boolean
    attribute :forced_submission_date, :date_time

    def proctored?
      proctored
    end

    def reactivated?
      forced_submission_date&.future?
    end
  end
end
