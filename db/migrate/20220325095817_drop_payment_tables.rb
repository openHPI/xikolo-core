# frozen_string_literal: true

class DropPaymentTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :invoice_addresses
    drop_table :payments
    drop_table :reference_nr_counts
  end
end
