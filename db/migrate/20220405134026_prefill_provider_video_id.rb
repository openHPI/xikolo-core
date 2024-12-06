# frozen_string_literal: true

class PrefillProviderVideoID < ActiveRecord::Migration[5.2]
  def up
    execute 'UPDATE streams SET provider_video_id = vimeo_id'
  end
end
