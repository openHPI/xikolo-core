# frozen_string_literal: true

class AddStorylineMetadataToCmi5Items < ActiveRecord::Migration[8.1]
  def change
    change_table :cmi5_items, bulk: true do |t|
      t.integer :player_width
      t.integer :player_height
    end
  end
end
