# frozen_string_literal: true

class BackfillDeemphasizedInNavOnItems < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      execute <<~SQL.squish
        UPDATE items SET deemphasized_in_nav = true WHERE show_in_nav IS NOT TRUE
      SQL
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
