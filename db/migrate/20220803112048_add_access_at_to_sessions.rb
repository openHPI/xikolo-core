# frozen_string_literal: true

class AddAccessAtToSessions < ActiveRecord::Migration[6.0]
  def change
    change_table :sessions, bulk: true do |t|
      t.date :access_at
      t.index :access_at
    end

    reversible do |dir|
      dir.up do
        # manually initialize existing sessions with today's date
        execute("UPDATE sessions SET access_at = '#{Time.zone.today.iso8601}'")

        # set the desired default value
        change_column_default :sessions, :access_at, -> { 'CURRENT_DATE' }
        change_column_null :sessions, :access_at, false
      end
    end
  end
end
