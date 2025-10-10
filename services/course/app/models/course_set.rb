# frozen_string_literal: true

class CourseSet < ApplicationRecord
  self.table_name = :course_sets

  has_many :course_set_entries, dependent: :delete_all

  has_many :courses,
    through: :course_set_entries

  has_many :course_set_relations,
    foreign_key: :source_set_id,
    inverse_of: :source_set,
    dependent: :delete_all

  has_many :linked_sets,
    through: :course_set_relations,
    class_name: 'CourseSet',
    source: :target_set
end
