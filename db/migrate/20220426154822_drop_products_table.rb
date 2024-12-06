# frozen_string_literal: true

class DropProductsTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :products

    remove_column :vouchers, :product_id
  end
end
