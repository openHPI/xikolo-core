# frozen_string_literal: true

class AddUniqueIndexOnAuthorizationsProviderAndUid < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :authorizations, %i[provider uid], unique: true, algorithm: :concurrently
  end

  def down
    remove_index :authorizations, column: %i[provider uid], algorithm: :concurrently
  end
end
