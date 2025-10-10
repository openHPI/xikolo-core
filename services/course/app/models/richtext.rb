# frozen_string_literal: true

class Richtext < ApplicationRecord
  self.table_name = :richtexts

  belongs_to :course
  validates :text, presence: true
end
