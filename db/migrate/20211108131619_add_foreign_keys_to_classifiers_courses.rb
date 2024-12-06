# frozen_string_literal: true

class AddForeignKeysToClassifiersCourses < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :classifiers_courses, :classifiers, on_delete: :cascade
    add_foreign_key :classifiers_courses, :courses, on_delete: :cascade
  end
end
