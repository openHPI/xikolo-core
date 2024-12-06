# frozen_string_literal: true

class AddRequiredItemIdsToItems < ActiveRecord::Migration[6.0]
  def change
    add_column :items, :required_item_ids, :uuid, array: true, default: [], null: false
  end
end
