# frozen_string_literal: true

class CourseSetEntry < ApplicationRecord
  self.table_name = :course_set_entries
  self.primary_key = %i[course_set_id course_id]

  belongs_to :course
  belongs_to :course_set
end
