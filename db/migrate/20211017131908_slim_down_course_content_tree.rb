# frozen_string_literal: true

class SlimDownCourseContentTree < ActiveRecord::Migration[5.2]
  def change
    create_table :forks, id: :uuid do |t|
      t.string :title
      t.references :content_test, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    create_table :branches, id: :uuid do |t|
      t.string :title
      t.references :group, type: :uuid, null: false, foreign_key: true
      t.timestamps
    end

    change_table :nodes, bulk: true do |t|
      # We create foreign key constraints only after the data has been migrated.
      # See the comment there for details.
      t.references :fork, type: :uuid, null: true
      t.references :branch, type: :uuid, null: true
    end

    reversible do |dir|
      dir.up do
        # Migrate fork and branch nodes to their own tables.
        #
        # To ease the migration, we created the `branch_id` and `fork_id` column
        # without foreign key constraints. This enables us to fill them with new
        # random UUIDs upfront. We can now use this ID to insert the `forks` and
        # `branches`. This way, we do not need to "remember" which new fork and
        # branch corresponds to which node.
        execute <<~SQL.squish
          UPDATE nodes SET fork_id = gen_random_uuid() WHERE content_test_id IS NOT NULL;

          INSERT INTO forks (id, title, content_test_id, created_at, updated_at)
          SELECT fork_id, title, content_test_id, created_at, updated_at
          FROM nodes WHERE fork_id IS NOT NULL;
        SQL

        execute <<~SQL.squish
          UPDATE nodes SET branch_id = gen_random_uuid() WHERE group_id IS NOT NULL;

          INSERT INTO branches (id, title, group_id, created_at, updated_at)
          SELECT branch_id, title, group_id, created_at, updated_at
          FROM nodes WHERE branch_id IS NOT NULL;
        SQL
      end

      dir.down do
        execute <<~SQL.squish
          UPDATE nodes
          SET group_id = branches.group_id, title = branches.title
          FROM branches WHERE branches.id = nodes.branch_id;

          UPDATE nodes
          SET content_test_id = forks.content_test_id, title = forks.title
          FROM forks WHERE forks.id = nodes.fork_id;
        SQL
      end
    end

    # Finally add foreign key constraints...
    add_foreign_key :nodes, :forks
    add_foreign_key :nodes, :branches

    # ... and remove old column.
    remove_column :nodes, :title, :string
    remove_reference :nodes, :group, type: :uuid, foreign_key: true
    remove_reference :nodes, :content_test, type: :uuid, foreign_key: true
  end
end
