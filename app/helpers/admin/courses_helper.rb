# frozen_string_literal: true

module Admin
  module CoursesHelper
    def course_status_class(status)
      case status
        when 'active'      then 'x-badge-success'
        when 'preparation' then 'x-badge-info'
        when 'self-paced', 'upcoming' then 'x-badge-neutral'
        else ''
      end
    end
  end
end
