# frozen_string_literal: true

class RemoveLiveEventsTable < ActiveRecord::Migration[7.2]
  def up
    drop_table :live_events if table_exists?(:live_events)
  end
end
