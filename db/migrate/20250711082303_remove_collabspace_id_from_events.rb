# frozen_string_literal: true

class RemoveCollabspaceIDFromEvents < ActiveRecord::Migration[7.2]
  def up
    remove_column :events, :collab_space_id, :uuid
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
