# frozen_string_literal: true

class ValidateCourseVisualsVideoForeignKey < ActiveRecord::Migration[8.1]
  def change
    validate_foreign_key :course_visuals, :videos
  end
end
