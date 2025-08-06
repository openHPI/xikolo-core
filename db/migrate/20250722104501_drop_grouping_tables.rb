# frozen_string_literal: true

class DropGroupingTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :assignment_rules
    drop_table :filters_user_tests
    drop_table :filters
    drop_table :metrics_user_tests
    drop_table :metrics
    drop_table :test_groups
    drop_table :trials
    drop_table :trial_results
    drop_table :user_tests
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
