# frozen_string_literal: true

##
# Legacy data from the old Canvas-based platform. These
# were created manually and can be considered read-only.
#
class FixedLearningEvaluation < ApplicationRecord
  self.primary_key = %i[course_id user_id]

  belongs_to :course
end
