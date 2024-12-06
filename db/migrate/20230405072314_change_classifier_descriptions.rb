# frozen_string_literal: true

class ChangeClassifierDescriptions < ActiveRecord::Migration[6.0]
  def change
    reversible do |dir|
      change_table :classifiers, bulk: true do |t|
        dir.up do
          t.remove :description
          t.column :descriptions, :jsonb, default: {}, null: false
        end

        dir.down do
          t.remove :descriptions
          t.column :description, :string
        end
      end
    end
  end
end
