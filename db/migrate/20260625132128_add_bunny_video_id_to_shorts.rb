# frozen_string_literal: true

class AddBunnyVideoIDToShorts < ActiveRecord::Migration[7.2]
  def change
    add_column :shorts, :bunny_video_id, :string
  end
end
