# frozen_string_literal: true

class MakeUserStatusRequired < ActiveRecord::Migration[7.2]
  disable_ddl_transaction! # so we can commit in between batches safely

  BATCH_SIZE = 1000

  def up
    say_with_time "Backfilling missing user.status values in batches of #{BATCH_SIZE}" do
      Account::User.where(status: nil)
        .in_batches(of: BATCH_SIZE)
        .update_all(status: 'other')
    end

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
