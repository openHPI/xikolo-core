# frozen_string_literal: true

# Tracks the lifecycle of a stream's upload to its provider (e.g. Bunny).
#
# A stream is created as soon as a video is uploaded, before it exists on the
# provider. `upload_state` records how far the background upload job has
# progressed so the admin UI can show it (waiting / uploading / ready /
# failed). `upload_error` holds the last failure reason for failed uploads.
#
# Non-Bunny providers (e.g. Vimeo) are managed by the provider sync instead,
# so their streams default to 'ready' and never show upload states.
class AddUploadStateToStreams < ActiveRecord::Migration[8.1]
  # rubocop:disable Rails/BulkChangeTable
  def up
    add_column :streams, :upload_state, :string, null: false, default: 'ready'
    add_column :streams, :upload_error, :string
  end

  def down
    remove_column :streams, :upload_error
    remove_column :streams, :upload_state
  end
  # rubocop:enable all
end
