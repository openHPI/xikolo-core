# frozen_string_literal: true

class CreateNodes < ActiveRecord::Migration[5.2]
  def change
    create_table :nodes, id: :uuid do |t|
      t.string :type, null: false, index: true
      t.string :title
      t.references :course, type: :uuid, null: false, foreign_key: true
      t.references :parent, type: :uuid, null: true, foreign_key: {to_table: :nodes}

      t.integer :lft, null: false, index: true
      t.integer :rgt, null: false, index: true
      t.integer :depth, null: false, default: 0
      t.integer :children_count, null: false, default: 0

      # Optional references to linked content objects
      t.references :section, type: :uuid, null: true, foreign_key: true
      t.references :group, type: :uuid, null: true, foreign_key: true
      t.references :item, type: :uuid, null: true, foreign_key: true

      # No foreign key as content tests do not exist yet
      t.references :content_test, type: :uuid, null: true

      t.timestamps
    end
  end
end
