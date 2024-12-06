# frozen_string_literal: true

class AddRoundRobinCounterToContentTests < ActiveRecord::Migration[5.2]
  def change
    add_column :content_tests, :round_robin_counter, :integer, null: false, default: 0
  end
end
