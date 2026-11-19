# frozen_string_literal: true

class RenameFormatToCourseFormat < ActiveRecord::Migration[7.2]
  def change
    drop_view :embed_courses, revert_to_version: 4

    rename_column :courses, :format, :course_format

    create_view :embed_courses, version: 4
  end
end
