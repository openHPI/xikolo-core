# frozen_string_literal: true

class AddProgressRecalculationTimestampsToDomainModels < ActiveRecord::Migration[6.0]
  def change
    change_table :courses do |t|
      t.datetime :progress_stale_at
    end

    change_table :sections do |t|
      t.datetime :progress_stale_at
    end
  end
end
