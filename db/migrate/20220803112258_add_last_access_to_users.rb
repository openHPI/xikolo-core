# frozen_string_literal: true

class AddLastAccessToUsers < ActiveRecord::Migration[6.0]
  def change
    change_table :users, bulk: true do |t|
      t.date :last_access
      t.index :last_access
    end
  end
end
