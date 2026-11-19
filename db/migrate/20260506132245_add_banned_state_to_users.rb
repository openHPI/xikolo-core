# frozen_string_literal: true

class AddBannedStateToUsers < ActiveRecord::Migration[7.2]
  def up
    change_table :users, bulk: true do |t|
      t.datetime :banned_at
      t.integer :ban_count, null: false, default: 0
    end

    add_index :users, :banned_at unless index_exists?(:users, :banned)

    remove_index :users, name: 'index_users_active', if_exists: true

    add_index :users,
      :created_at,
      name: 'index_users_active',
      where: '((confirmed = true) AND (archived = false) AND (banned_at IS NOT NULL) AND (anonymous = false))'
  end

  def down
    remove_index :users, name: 'index_users_active', if_exists: true

    add_index :users,
      :created_at,
      name: 'index_users_active',
      where: '((confirmed = true) AND (archived = false) AND (anonymous = false))'

    remove_index :users, :banned_at, if_exists: true

    change_table :users, bulk: true do |t|
      t.remove :banned_at
      t.remove :ban_count
    end
  end
end
