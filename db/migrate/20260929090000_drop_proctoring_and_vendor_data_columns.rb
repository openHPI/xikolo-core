# frozen_string_literal: true

class DropProctoringAndVendorDataColumns < ActiveRecord::Migration[8.1]
  def up
    # Drop the view since it depends on courses.*
    drop_view :embed_courses

    change_table :courses, bulk: true do |t|
      t.remove :proctored
    end

    change_table :enrollments, bulk: true do |t|
      t.remove :proctored
    end

    change_table :items, bulk: true do |t|
      t.remove :proctored
      t.remove :icon_type
    end

    change_table :quiz_submissions, bulk: true do |t|
      t.remove :vendor_data
    end

    # Recreate the embed_courses view without dropped columns
    create_view :embed_courses, version: 4
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
