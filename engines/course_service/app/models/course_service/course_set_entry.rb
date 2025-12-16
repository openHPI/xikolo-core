# frozen_string_literal: true

module CourseService
class CourseSetEntry < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :course_set_entries
  self.primary_key = %i[course_set_id course_id]

  belongs_to :course
  belongs_to :course_set
end
end
