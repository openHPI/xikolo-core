# frozen_string_literal: true

class AddProviderIDToVideoStreams < ActiveRecord::Migration[5.2]
  def change
    add_column :streams, :provider_video_id, :string
  end
end
