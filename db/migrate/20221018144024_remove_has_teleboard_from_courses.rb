# frozen_string_literal: true

class RemoveHasTeleboardFromCourses < ActiveRecord::Migration[6.0]
  def up
    drop_view :embed_courses
    remove_column :courses, :has_teleboard, :boolean
    create_view :embed_courses, version: 4
  end
end
