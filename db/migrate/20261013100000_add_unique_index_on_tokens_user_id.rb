# frozen_string_literal: true

class AddUniqueIndexOnTokensUserID < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :tokens, :user_id, unique: true, algorithm: :concurrently
  end

  def down
    remove_index :tokens, column: :user_id, algorithm: :concurrently
  end
end
