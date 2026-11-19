# frozen_string_literal: true

module CourseService
  class ClassifierAssignment < ApplicationRecord
    self.table_name = 'classifiers_courses'
    self.primary_key = %i[classifier_id course_id]

    belongs_to :classifier
    belongs_to :course
  end
end
