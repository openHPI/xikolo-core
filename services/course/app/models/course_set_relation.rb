# frozen_string_literal: true

class CourseSetRelation < ApplicationRecord
  self.table_name = :course_set_relations

  belongs_to :source_set,
    class_name: 'CourseSet',
    inverse_of: :course_set_relations

  belongs_to :target_set,
    class_name: 'CourseSet',
    inverse_of: false

  has_many :target_courses,
    through: :target_set,
    source: :courses
end
