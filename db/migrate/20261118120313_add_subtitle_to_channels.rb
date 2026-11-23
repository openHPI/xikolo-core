# frozen_string_literal: true

class AddSubtitleToChannels < ActiveRecord::Migration[8.1]
  def change
    add_column :channels, :subtitle, :jsonb
  end
end
