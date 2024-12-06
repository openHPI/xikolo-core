# frozen_string_literal: true

module Xikolo
  module Entities
    class CourseDate < Grape::Entity
      include Rails.application.routes.url_helpers

      expose def id
        id = "#{object.course_id}|#{object.type}|#{object.resource_id}"
        Digest::MD5.hexdigest id
      end

      expose :title
      expose :date
      expose :type

      expose def url
        case type
          when 'course_start'
            course_path object.course_code
          when 'item_submission_deadline'
            course_item_path object.course_code, UUID(object.resource_id).to_param
        end
      end

      expose def course
        object.course_id
      end
    end
  end
end
