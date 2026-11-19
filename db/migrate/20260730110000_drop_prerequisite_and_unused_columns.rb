# frozen_string_literal: true

class DropPrerequisiteAndUnusedColumns < ActiveRecord::Migration[8.1]
  def up
    # Drop the view since it depends on courses.*
    drop_view :embed_courses, materialized: false

    # Drop prerequisite feature tables (in reverse dependency order)
    drop_table :course_set_entries, if_exists: true, force: :cascade do |t|
      t.uuid :course_id, null: false
      t.uuid :course_set_id, null: false
    end

    drop_table :course_set_relations, if_exists: true, force: :cascade do |t|
      t.datetime :created_at, precision: nil, null: false
      t.string :kind
      t.uuid :source_set_id
      t.uuid :target_set_id
      t.datetime :updated_at, precision: nil, null: false
    end

    drop_table :course_sets, if_exists: true, force: :cascade do |t|
      t.datetime :created_at, precision: nil, null: false
      t.string :name
      t.datetime :updated_at, precision: nil, null: false
    end

    # Drop unused/ignored columns from courses table
    change_table :courses, bulk: true do |t|
      t.remove :auto_archive, :show_syllabus, :show_on_stage,
        :stage_visual_uri, :stage_statement, :policy_url,
        :external_registration_url
    end

    # Recreate the embed_courses view without dropped columns
    create_view :embed_courses, version: 4
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
