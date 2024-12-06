# frozen_string_literal: true

class CreateContentTests < ActiveRecord::Migration[5.2]
  def change
    create_table :content_tests, id: :uuid do |t|
      t.uuid :course_id
      t.uuid :groups, array: true, default: []

      t.timestamps
    end

    add_foreign_key :content_tests, :courses
  end
end
