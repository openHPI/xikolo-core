# frozen_string_literal: true

class AddFormatToCourses < ActiveRecord::Migration[7.2]
  def change
    drop_view :embed_courses, revert_to_version: 4

    create_enum :course_format, %w[course workshop project]

    add_column :courses, :format, :course_format,
      default: 'course',
      null: false

    create_view :embed_courses, version: 4
  end
end
