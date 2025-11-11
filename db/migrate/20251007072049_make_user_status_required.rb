# frozen_string_literal: true

class MakeUserStatusRequired < ActiveRecord::Migration[7.2]
  def up
    say_with_time 'Adding NOT NULL constraint to users.status' do
      change_column_null :users, :status, false
    end
  end

  def down
    say_with_time 'Removing NOT NULL constraint from users.status' do
      change_column_null :users, :status, true
    end
  end
end
