# frozen_string_literal: true

class RemoveVideoUploadAttributes < ActiveRecord::Migration[5.2]
  # rubocop:disable Rails/BulkChangeTable
  def change
    remove_column :peer_assessments, :video_upload_allowed, :boolean, default: false
    remove_column :peer_assessments, :video_provider_name, :string

    remove_column :shared_submissions, :has_video_upload, :boolean, default: false, null: false
    remove_column :shared_submissions, :video_upload_url, :string
  end
  # rubocop:enable all
end
