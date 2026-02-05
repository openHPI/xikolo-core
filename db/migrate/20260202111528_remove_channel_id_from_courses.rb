# frozen_string_literal: true

class RemoveChannelIDFromCourses < ActiveRecord::Migration[7.2]
  def up
    drop_view :embed_courses, materialized: false

    remove_column :courses, :channel_id

    create_view :embed_courses, version: 4
  end

  def down
    drop_view :embed_courses, materialized: false

    add_column :courses, :channel_id, :uuid

    create_view :embed_courses, version: 4
  end
end
