# frozen_string_literal: true

class AddReadingMaterialURIToRichtexts < ActiveRecord::Migration[8.1]
  def change
    add_column :richtexts, :reading_material_uri, :string
  end
end
