# frozen_string_literal: true

module Xikolo::Course
  class Statistic < Acfs::SingletonResource
    service Xikolo::Course::Client, path: '/courses/:course_id/statistic'
    attribute :course_id, :uuid
    attribute :enrollments, :integer
    attribute :current_enrollments, :integer
    attribute :last_day_enrollments, :integer
  end
end
