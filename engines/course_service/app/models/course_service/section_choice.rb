# frozen_string_literal: true

module CourseService
class SectionChoice < ApplicationRecord # rubocop:disable Layout/IndentationWidth
  self.table_name = :section_choices
  self.primary_key = %i[section_id user_id]

  after_initialize :default_values

  validates :user_id, presence: true
  belongs_to :section
  validates :section_id, uniqueness: {scope: :user_id}

  private

  def default_values
    self.choice_ids = [] unless choice_ids.is_a?(Array)
  end
end
end
