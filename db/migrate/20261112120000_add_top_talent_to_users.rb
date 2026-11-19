# frozen_string_literal: true

class AddTopTalentToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :top_talent, :boolean, null: false, default: false
    create_enum :top_talent_source, %w[admin course]

    create_table :user_top_talents, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: {to_table: :users}
      t.enum :source, enum_type: :top_talent_source, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :user_top_talents, %i[user_id source], unique: true
  end
end
