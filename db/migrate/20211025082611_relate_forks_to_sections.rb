# frozen_string_literal: true

class RelateForksToSections < ActiveRecord::Migration[5.2]
  def change
    # Create the foreign key, but allow NULLs for now
    add_reference :forks, :section, type: :uuid, foreign_key: true

    # Correctly fill the new field based on existing course content tree data
    up_only do
      execute <<~SQL.squish
        UPDATE forks SET (section_id) = (
          SELECT sections.id FROM sections
            INNER JOIN nodes AS section_nodes ON section_nodes.section_id = sections.id
            INNER JOIN nodes AS fork_nodes ON fork_nodes.parent_id = section_nodes.id AND fork_nodes.type = 'fork'
            INNER JOIN forks ON forks.id = fork_nodes.fork_id
            LIMIT 1
        )
      SQL
    end

    # Now that the field has been backfilled, disallow NULLs
    change_column_null :forks, :section_id, false
  end
end
