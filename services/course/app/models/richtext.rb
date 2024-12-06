# frozen_string_literal: true

class Richtext < ApplicationRecord
  belongs_to :course
  validates :text, presence: true
end
