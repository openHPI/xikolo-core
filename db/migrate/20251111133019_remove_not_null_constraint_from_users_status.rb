# frozen_string_literal: true

class RemoveNotNullConstraintFromUsersStatus < ActiveRecord::Migration[7.2]
  def change
    change_column_null :users, :status, true
  end
end
