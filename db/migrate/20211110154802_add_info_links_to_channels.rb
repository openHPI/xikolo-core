# frozen_string_literal: true

class AddInfoLinksToChannels < ActiveRecord::Migration[5.2]
  def change
    add_column :channels, :info_link, :jsonb, null: false, default: {}
  end
end
