# frozen_string_literal: true

class RemoveNameFromChannels < ActiveRecord::Migration[7.2]
  def change
    remove_column :channels, :name, :string
  end
end
