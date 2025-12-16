# frozen_string_literal: true

module CourseService
class Richtext < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :richtexts

  belongs_to :course
  validates :text, presence: true
end
end
