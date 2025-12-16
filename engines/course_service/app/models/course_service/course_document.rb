# frozen_string_literal: true

module CourseService
  class CourseDocument < ApplicationRecord
    self.table_name = :courses_documents

    belongs_to :course
    belongs_to :document
  end
end
