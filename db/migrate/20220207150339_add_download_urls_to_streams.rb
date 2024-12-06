# frozen_string_literal: true

class AddDownloadUrlsToStreams < ActiveRecord::Migration[5.2]
  def change
    change_table :streams, bulk: true do |t|
      t.string :sd_download_url
      t.string :hd_download_url
    end
  end
end
