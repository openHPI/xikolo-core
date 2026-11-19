# frozen_string_literal: true

class AddMinimumProgressPercentageToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :minimum_progress_percentage, :integer, default: 75
  end
end
