# frozen_string_literal: true

module PinboardService
class Tag < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :tags

  has_and_belongs_to_many :questions

  validates :course_id, presence: true

  scope :by_name, ->(name) { where('LOWER(name) = ?', name.downcase) }
end
end
