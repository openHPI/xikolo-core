# frozen_string_literal: true

class DropQuotesTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :quotes
  end
end
