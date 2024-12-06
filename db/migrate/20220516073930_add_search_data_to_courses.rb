# frozen_string_literal: true

class AddSearchDataToCourses < ActiveRecord::Migration[5.2]
  def change
    change_table :courses, bulk: true do |t|
      t.text :search_data
      t.index :search_data, opclass: :gin_trgm_ops, using: :gin
    end

    update_view :embed_courses, version: 4, revert_to_version: 4
  end
end
