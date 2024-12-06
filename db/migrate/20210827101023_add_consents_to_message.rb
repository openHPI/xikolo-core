# frozen_string_literal: true

class AddConsentsToMessage < ActiveRecord::Migration[5.2]
  def change
    add_column :messages, :consents, :jsonb, default: [], null: false
  end
end
