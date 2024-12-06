# frozen_string_literal: true

class DropHangoutsTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :hangouts
  end
end
