# frozen_string_literal: true

class Tag < ApplicationRecord
  has_and_belongs_to_many :questions

  validates :course_id, presence: true

  scope :by_name, ->(name) { where('LOWER(name) = ?', name.downcase) }
end
