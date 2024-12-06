# frozen_string_literal: true

class RelateBranchesToForks < ActiveRecord::Migration[5.2]
  def change
    # Create the foreign key, but allow NULLs for now
    add_reference :branches, :fork, type: :uuid, foreign_key: true

    # Correctly fill the new field based on existing course content tree data
    up_only do
      execute <<~SQL.squish
        UPDATE branches SET (fork_id) = (
          SELECT forks.id FROM forks
            INNER JOIN nodes AS fork_nodes ON fork_nodes.fork_id = forks.id
            INNER JOIN nodes AS branch_nodes ON branch_nodes.parent_id = fork_nodes.id
            INNER JOIN branches ON branches.id = branch_nodes.branch_id
            LIMIT 1
        )
      SQL
    end

    # Now that the field has been backfilled, disallow NULLs
    change_column_null :branches, :fork_id, false
  end
end
