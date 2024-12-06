# frozen_string_literal: true

class AddPinboardEnabledToCourses < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :pinboard_enabled, :boolean, default: true, null: false

    update_view :embed_courses, version: 4, revert_to_version: 4
  end
end
