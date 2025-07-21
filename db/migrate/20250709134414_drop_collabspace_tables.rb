# frozen_string_literal: true

class DropCollabspaceTables < ActiveRecord::Migration[7.2]
  def up
    drop_table :calendar_events
    drop_table :file_versions
    drop_table :files
    drop_table :collab_space_memberships
    drop_table :collab_spaces
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
