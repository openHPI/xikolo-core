# frozen_string_literal: true

class AddProgressRecalculationTimestamps < ActiveRecord::Migration[6.0]
  def change
    change_table :nodes do |t|
      t.datetime :progress_stale_at
    end

    change_table :courses do |t|
      t.datetime :progress_calculated_at
    end
  end
end
