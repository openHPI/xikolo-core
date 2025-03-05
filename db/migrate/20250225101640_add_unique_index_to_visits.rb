# frozen_string_literal: true

class AddUniqueIndexToVisits < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    add_index :visits, %i[user_id item_id], unique: true, algorithm: :concurrently
  end

  def down
    remove_index :visits, column: %i[user_id item_id], algorithm: :concurrently
  end
end
