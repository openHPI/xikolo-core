# frozen_string_literal: true

module CourseService
##
# Legacy data from the old Canvas-based platform. These
# were created manually and can be considered read-only.
#
class FixedLearningEvaluation < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :fixed_learning_evaluations
  self.primary_key = %i[course_id user_id]

  belongs_to :course
end
end
