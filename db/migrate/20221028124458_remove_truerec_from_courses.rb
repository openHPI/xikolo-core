# frozen_string_literal: true

class RemoveTruerecFromCourses < ActiveRecord::Migration[6.0]
  def up
    drop_view :embed_courses
    remove_column :courses, :truerec, :boolean
    create_view :embed_courses, version: 4
  end
end
