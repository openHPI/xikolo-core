# frozen_string_literal: true

class RemoveVimeoIDFromStreams < ActiveRecord::Migration[6.1]
  def change
    remove_column :streams, :vimeo_id, :integer
  end
end
