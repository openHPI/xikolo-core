# frozen_string_literal: true

class AddCmi5Files < ActiveRecord::Migration[7.2]
  def change
    create_table :cmi5_files, id: :uuid, default: -> { 'uuid_generate_v7ms()' } do |t|
      t.references :cmi5_item, type: :uuid, null: false
      t.string :file_path
      t.timestamps
    end
  end
end
