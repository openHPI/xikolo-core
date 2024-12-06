# frozen_string_literal: true

class AddSearchIndexToCourses < ActiveRecord::Migration[5.2]
  def change
    change_table :courses, bulk: true do |t|
      t.tsvector :tsv
      t.index :tsv, using: :gin
    end

    update_view :embed_courses, version: 4, revert_to_version: 4
  end
end
