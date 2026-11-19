# frozen_string_literal: true

class RemoveOpenBadgeTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :open_badge_templates if table_exists?(:open_badge_templates)
    drop_table :open_badges if table_exists?(:open_badges)
  end

  def down
    create_table :open_badge_templates do |table|
      table.uuid :course_id, null: false
      table.text :svg
      table.string :name
      table.text :description
      table.datetime :created_at, precision: nil
      table.datetime :updated_at, precision: nil
      table.string :file_uri
    end

    add_index :open_badge_templates, %i[course_id], name: 'index_open_badge_templates_on_course_id', unique: true

    create_table :open_badges do |table|
      table.uuid :record_id, null: false
      table.uuid :template_id, null: false
      table.jsonb :assertion
      table.datetime :created_at, precision: nil
      table.datetime :updated_at, precision: nil
      table.string :file_uri
      table.string :type, default: 'OpenBadge'
    end

    add_index :open_badges, %i[type], name: 'index_open_badges_on_type'
    add_index :open_badges, %i[record_id template_id], name: 'index_open_badges_on_record_id_and_template_id'
  end
end
