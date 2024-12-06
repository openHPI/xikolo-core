# frozen_string_literal: true

class RemoveDeletedFromSections < ActiveRecord::Migration[5.2]
  def change
    remove_column :sections, :deleted, :boolean, default: false, null: false
  end
end
