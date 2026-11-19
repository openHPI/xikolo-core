# frozen_string_literal: true

class DropTargetGroupsFromCourses < ActiveRecord::Migration[8.1]
  def up
    drop_view :embed_courses

    safety_assured do
      remove_column :courses, :target_groups
    end

    create_view :embed_courses, version: 4
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
