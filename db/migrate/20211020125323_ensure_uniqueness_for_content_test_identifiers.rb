# frozen_string_literal: true

class EnsureUniquenessForContentTestIdentifiers < ActiveRecord::Migration[5.2]
  def change
    change_column_null :content_tests, :identifier, false
    add_index :content_tests, %i[course_id identifier], unique: true
  end
end
