# frozen_string_literal: true

class RemoveFeaturedFromItems < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :items, :featured, :boolean, default: false, null: false
    end
  end
end
