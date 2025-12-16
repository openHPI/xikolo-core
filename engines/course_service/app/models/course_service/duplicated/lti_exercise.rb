# frozen_string_literal: true

module CourseService
module Duplicated # rubocop:disable Layout/IndentationWidth
  class LtiExercise < ApplicationRecord
    self.table_name = :lti_exercises

    belongs_to :lti_provider, class_name: 'CourseService::Duplicated::LtiProvider'
  end
end
end
