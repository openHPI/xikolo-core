# frozen_string_literal: true

# rubocop:disable Rails/BulkChangeTable
# rubocop:disable Rails/ReversibleMigration
class ModifyContentTests < ActiveRecord::Migration[5.2]
  def change
    add_column :content_tests, :identifier, :string
    change_column :content_tests, :groups, :string, array: true, default: [], null: false
  end
end
# rubocop:enable all
