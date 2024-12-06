# frozen_string_literal: true

module Collabspace::ConstantsHelper
  MEMBERSHIP_TYPE = {admin: 'admin', mentor: 'mentor', regular: 'regular'}.freeze
  MEMBERSHIP_STATUS = {member: 'regular', pending: 'pending'}.freeze
  LAYOUTS = {course_area_two_cols: 'course_area_two_cols', course_area: 'course_area'}.freeze
end
