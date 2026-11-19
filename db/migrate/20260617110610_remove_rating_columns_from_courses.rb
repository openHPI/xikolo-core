# frozen_string_literal: true

class RemoveRatingColumnsFromCourses < ActiveRecord::Migration[7.2]
  def up
    drop_view :embed_courses, materialized: false

    change_table :courses, bulk: true do |t|
      t.remove :rating_stars
      t.remove :rating_votes
    end

    create_view :embed_courses, version: 4
  end

  def down
    drop_view :embed_courses, materialized: false

    change_table :courses, bulk: true do |t|
      t.float :rating_stars
      t.integer :rating_votes
    end

    create_view :embed_courses, version: 4
  end
end
