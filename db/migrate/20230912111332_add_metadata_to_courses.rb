# frozen_string_literal: true

class AddMetadataToCourses < ActiveRecord::Migration[6.0]
  def change
    create_table :metadata, id: :uuid do |t|
      t.jsonb :data, default: []
      t.string :name, null: false
      t.string :version, null: false
      t.references :course, type: :uuid, null: false, foreign_key: true
      t.index %i[course_id name version], unique: true
      t.timestamps
    end
  end
end
