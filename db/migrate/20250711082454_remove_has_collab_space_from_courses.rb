# frozen_string_literal: true

class RemoveHasCollabSpaceFromCourses < ActiveRecord::Migration[7.2]
  def change
    drop_view :embed_courses
    remove_column :courses, :has_collab_space, :boolean
    create_view :embed_courses, version: 4
  end
end
