# frozen_string_literal: true

class CreateCourseVisuals < ActiveRecord::Migration[6.0]
  def change
    create_table :course_visuals, id: :uuid do |t|
      t.uuid :course_id, null: false
      t.uuid :video_id
      t.string :image_uri

      t.timestamps

      t.index :course_id, unique: true
    end
  end
end
