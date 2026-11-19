# frozen_string_literal: true

class ExtendContentTestSchema < ActiveRecord::Migration[5.2]
  # rubocop:disable-next Rails/BulkChangeTable
  def change
    change_column_null :content_tests, :course_id, false
    change_column_null :content_tests, :groups, false

    add_foreign_key :nodes, :content_tests
  end
end
