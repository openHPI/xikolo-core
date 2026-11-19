# frozen_string_literal: true

class RemoveShowInNavFromItems < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      remove_column :items, :show_in_nav, :boolean, default: false
    end
  end
end
