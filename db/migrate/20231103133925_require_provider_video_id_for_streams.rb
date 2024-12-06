# frozen_string_literal: true

class RequireProviderVideoIDForStreams < ActiveRecord::Migration[6.1]
  class Stream < ApplicationRecord; end

  def change
    up_only do
      Stream.where(provider_video_id: [nil, '']).delete_all
    end

    change_column_null :streams, :provider_video_id, false
  end
end
