# frozen_string_literal: true

module CourseService
class CourseSetRelation < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :course_set_relations

  belongs_to :source_set,
    class_name: 'CourseService::CourseSet',
    inverse_of: :course_set_relations

  belongs_to :target_set,
    class_name: 'CourseService::CourseSet',
    inverse_of: false

  has_many :target_courses,
    through: :target_set,
    source: :courses
end
end
