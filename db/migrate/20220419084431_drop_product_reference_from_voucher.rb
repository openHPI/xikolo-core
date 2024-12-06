# frozen_string_literal: true

class DropProductReferenceFromVoucher < ActiveRecord::Migration[5.2]
  def up
    change_column_null :vouchers, :product_id, true
  end
end
