# frozen_string_literal: true

class AddDownloadsExpireToStreams < ActiveRecord::Migration[5.2]
  def change
    add_column :streams, :downloads_expire, :datetime, null: true
  end
end
