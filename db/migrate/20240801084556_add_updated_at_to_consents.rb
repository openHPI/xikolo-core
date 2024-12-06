# frozen_string_literal: true

class AddUpdatedAtToConsents < ActiveRecord::Migration[6.1]
  def up
    add_column :consents, :updated_at, :datetime
    execute <<~SQL.squish
      UPDATE consents SET updated_at = created_at
    SQL
    change_column_null :consents, :updated_at, false, Time.zone.now
  end

  def down
    remove_column :consents, :updated_at
  end
end
