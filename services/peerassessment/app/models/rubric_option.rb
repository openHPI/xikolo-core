# frozen_string_literal: true

class RubricOption < ApplicationRecord
  belongs_to :rubric

  validates :points, presence: true

  default_scope { order('points ASC') }
end
