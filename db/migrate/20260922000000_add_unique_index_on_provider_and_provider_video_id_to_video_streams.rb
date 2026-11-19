# frozen_string_literal: true

class AddUniqueIndexOnProviderAndProviderVideoIDToVideoStreams < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    add_index :streams, %i[provider_id provider_video_id], unique: true, algorithm: :concurrently
  end

  def down
    remove_index :streams, column: %i[provider_id provider_video_id], algorithm: :concurrently
  end
end
