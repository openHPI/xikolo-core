# frozen_string_literal: true

class RemoveVideoUploadTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :submission_video_uploads
    drop_table :uploads
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
