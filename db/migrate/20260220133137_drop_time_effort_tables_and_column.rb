# frozen_string_literal: true

class DropTimeEffortTablesAndColumn < ActiveRecord::Migration[7.2]
  def up
    drop_table :time_effort_jobs, if_exists: true
    drop_table :time_effort_items, if_exists: true

    remove_column :items, :time_effort
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
