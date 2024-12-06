# frozen_string_literal: true

class AddNodeTypeEnum < ActiveRecord::Migration[5.2]
  def change
    create_enum :node_type, %w[root section item branch fork]

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE nodes SET type = 'root' WHERE type = 'Structure::Root';
          UPDATE nodes SET type = 'section' WHERE type = 'Structure::Section';
          UPDATE nodes SET type = 'item' WHERE type = 'Structure::Item';
          UPDATE nodes SET type = 'branch' WHERE type = 'Structure::Branch';
          UPDATE nodes SET type = 'fork' WHERE type = 'Structure::Fork';

          ALTER TABLE nodes ALTER COLUMN type TYPE node_type USING type::node_type;
        SQL
      end

      dir.down do
        execute <<~SQL.squish
          ALTER TABLE nodes ALTER COLUMN type TYPE varchar;

          UPDATE nodes SET type = 'Structure::Root' WHERE type = 'root';
          UPDATE nodes SET type = 'Structure::Section' WHERE type = 'section';
          UPDATE nodes SET type = 'Structure::Item' WHERE type = 'item';
          UPDATE nodes SET type = 'Structure::Branch' WHERE type = 'branch';
          UPDATE nodes SET type = 'Structure::Fork' WHERE type = 'fork';
        SQL
      end
    end
  end
end
