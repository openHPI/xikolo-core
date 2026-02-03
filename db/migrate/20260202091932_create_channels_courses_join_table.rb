# frozen_string_literal: true

class CreateChannelsCoursesJoinTable < ActiveRecord::Migration[7.2]
  def change
    create_table :channels_courses, primary_key: %i[channel_id course_id] do |t|
      t.references :channel, null: false, type: :uuid, foreign_key: true, index: false
      t.references :course, null: false, type: :uuid, foreign_key: true
      t.timestamps
    end
  end
end
