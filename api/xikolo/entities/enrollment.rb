# frozen_string_literal: true

module Xikolo
  module Entities
    class Enrollment < Grape::Entity
      expose :id

      expose def user
        object.user_id
      end

      expose def course
        object.course_id
      end

      expose def reactivated
        object.forced_submission_date.present? && Time.zone.parse(object.forced_submission_date).future?
      end

      expose :points
      expose :certificates
      expose :completed
      expose :quantile
      expose :proctored
    end
  end
end
