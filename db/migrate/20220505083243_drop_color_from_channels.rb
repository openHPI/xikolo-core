# frozen_string_literal: true

class DropColorFromChannels < ActiveRecord::Migration[5.2]
  def change
    remove_column :channels, :color, :string, null: false
  end
end
