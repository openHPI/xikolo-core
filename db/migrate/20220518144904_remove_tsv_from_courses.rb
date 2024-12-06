# frozen_string_literal: true

class RemoveTsvFromCourses < ActiveRecord::Migration[5.2]
  def up
    drop_view :embed_courses
    remove_column :courses, :tsv
    create_view :embed_courses, version: 4
  end
end
