# frozen_string_literal: true

class RemoveDeprecatedCourseVisualAttributesFromCourses < ActiveRecord::Migration[6.0]
  def up
    drop_view :embed_courses
    change_table :courses, bulk: true do |t|
      t.remove :visual_uri
      t.remove :vimeo_id
      t.remove :video_provider_id
    end
    create_view :embed_courses, version: 4
  end
end
