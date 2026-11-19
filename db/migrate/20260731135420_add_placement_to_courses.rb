# frozen_string_literal: true

class AddPlacementToCourses < ActiveRecord::Migration[8.1]
  def change
    drop_view :embed_courses, revert_to_version: 4

    add_column :courses, :placement, :string, array: true, default: [], null: false

    create_view :embed_courses, version: 4
  end

  def down
    drop_view :embed_courses, materialized: false

    remove_column :courses, :placement

    create_view :embed_courses, version: 4
  end
end
