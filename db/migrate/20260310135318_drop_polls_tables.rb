# frozen_string_literal: true

class DropPollsTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :poll_responses, if_exists: true
    drop_table :poll_options, if_exists: true
    drop_table :polls, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
