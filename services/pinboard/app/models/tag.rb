# frozen_string_literal: true

class Tag < ApplicationRecord
  include CourseOrLearningRoomValidationHelper

  has_and_belongs_to_many :questions

  validate :course_or_learning_room

  scope :by_name, ->(name) { where('LOWER(name) = ?', name.downcase) }
end
