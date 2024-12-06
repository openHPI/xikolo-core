# frozen_string_literal: true

class RemoveDeprecatedVisualsFromCourse < ActiveRecord::Migration[6.0]
  def up
    drop_view :embed_courses
    change_table :courses, bulk: true do |t|
      t.remove :visual_id
      t.remove :stage_visual_id
    end
    create_view :embed_courses, version: 4
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
