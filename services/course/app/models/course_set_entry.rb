# frozen_string_literal: true

class CourseSetEntry < ApplicationRecord
  self.primary_keys = :course_set_id, :course_id

  belongs_to :course
  belongs_to :course_set
end
