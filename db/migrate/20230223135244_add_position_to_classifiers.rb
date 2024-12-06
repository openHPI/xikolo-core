# frozen_string_literal: true

class AddPositionToClassifiers < ActiveRecord::Migration[6.0]
  def change
    add_column :classifiers, :position, :integer

    up_only do
      execute <<~SQL.squish
        UPDATE classifiers
        SET position = mapping.new_position
        FROM (
         SELECT
           id,
           ROW_NUMBER() OVER (
             PARTITION BY cluster_id
             ORDER BY title
           ) as new_position
         FROM classifiers
        ) AS mapping
        WHERE classifiers.id = mapping.id;
      SQL
    end
  end
end
