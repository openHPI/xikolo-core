# frozen_string_literal: true

class HideCoursesFromCourseList < ActiveRecord::Migration[5.2]
  def change
    add_column :courses, :show_on_list, :boolean, null: false, default: true

    update_view :embed_courses, version: 4, revert_to_version: 4
  end
end
