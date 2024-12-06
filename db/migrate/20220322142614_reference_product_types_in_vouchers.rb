# frozen_string_literal: true

class ReferenceProductTypesInVouchers < ActiveRecord::Migration[5.2]
  def change
    # Create the foreign key, but allow NULLs for now
    add_column :vouchers, :product_type, :string

    # Correctly fill the new field based on existing voucher/product data
    up_only do
      execute <<~SQL.squish
        UPDATE vouchers SET (product_type) = (
          SELECT products.product_type FROM products
            INNER JOIN vouchers ON vouchers.product_id = products.id
            LIMIT 1
        )
      SQL
    end

    # Now that the field has been backfilled, disallow NULLs
    change_column_null :vouchers, :product_type, false
  end
end
