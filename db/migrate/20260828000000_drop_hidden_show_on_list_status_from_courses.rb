# frozen_string_literal: true

class DropHiddenShowOnListStatusFromCourses < ActiveRecord::Migration[8.1]
  def up
    # Drop the view since it depends on courses.* and references hidden, show_on_list, status
    drop_view :embed_courses, materialized: false

    # Drop ignore entries for these columns from the Course model ignored_columns
    # (ignored_columns is handled by the model, not the schema, but we document intent here)

    # Drop columns from courses table
    change_table :courses, bulk: true do |t|
      t.remove :show_on_list, :status, :hidden
    end

    # Recreate the embed_courses view without show_on_list, status, hidden
    create_view :embed_courses, version: 4
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
