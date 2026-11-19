# frozen_string_literal: true

# Allows `streams.provider_video_id` to be null.
#
# A stream is persisted as soon as a video is uploaded, before it has been
# created on the provider (e.g. Bunny). The provider video id is backfilled by
# a background job once the create request succeeds, so the id may legitimately
# be absent for a short window. Postgres unique indexes ignore NULL values, so
# the existing unique index on (provider_id, provider_video_id) is unaffected.
class AllowNullProviderVideoGuidOnStreams < ActiveRecord::Migration[8.1]
  def up
    change_column :streams, :provider_video_id, :string, null: true
  end

  def down
    change_column :streams, :provider_video_id, :string, null: false
  end
end
