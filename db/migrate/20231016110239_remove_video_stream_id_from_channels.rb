# frozen_string_literal: true

class RemoveVideoStreamIDFromChannels < ActiveRecord::Migration[6.1]
  def up
    remove_column :channels, :video_stream_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
