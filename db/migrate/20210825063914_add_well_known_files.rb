# frozen_string_literal: true

class AddWellKnownFiles < ActiveRecord::Migration[5.2]
  def change
    create_table :well_known_files, id: false do |t|
      t.string :filename, limit: 64, primary_key: true
      t.text :content, null: false
      t.timestamps
    end
  end
end
