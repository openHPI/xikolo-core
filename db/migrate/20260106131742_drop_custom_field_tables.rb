# frozen_string_literal: true

class DropCustomFieldTables < ActiveRecord::Migration[7.2]
  def change
    drop_table :custom_field_values # rubocop:disable Rails/ReversibleMigration
    drop_table :custom_fields # rubocop:disable Rails/ReversibleMigration
  end
end
