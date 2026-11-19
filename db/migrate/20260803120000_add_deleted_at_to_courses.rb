# frozen_string_literal: true

class AddDeletedAtToCourses < ActiveRecord::Migration[7.2]
  def up
    drop_view :embed_courses, revert_to_version: 4

    add_column :courses, :deleted_at, :datetime, precision: nil

    create_view :embed_courses, version: 4
  end

  def down
    drop_view :embed_courses, materialized: false

    remove_column :courses, :deleted_at

    create_view :embed_courses, version: 4
  end
end
