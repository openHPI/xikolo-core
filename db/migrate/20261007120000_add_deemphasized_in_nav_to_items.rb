# frozen_string_literal: true

class AddDeemphasizedInNavToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :deemphasized_in_nav, :boolean, default: false, null: false
  end
end
