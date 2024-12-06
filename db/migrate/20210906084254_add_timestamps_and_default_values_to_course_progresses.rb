# frozen_string_literal: true

class AddTimestampsAndDefaultValuesToCourseProgresses < ActiveRecord::Migration[5.2]
  # rubocop:disable Rails/BulkChangeTable
  def change
    # Add new columns but allow null values
    add_timestamps :course_progresses, null: true

    # Fill existing records and add not null constraint
    change_column_null :course_progresses, :created_at, false, Time.zone.now
    change_column_null :course_progresses, :updated_at, false, Time.zone.now

    change_column_null :course_progresses, :visits, false, 0
    change_column_null :course_progresses, :main_dpoints, false, 0
    change_column_null :course_progresses, :main_exercises, false, 0
    change_column_null :course_progresses, :main_dpoints, false, 0
    change_column_null :course_progresses, :bonus_dpoints, false, 0
    change_column_null :course_progresses, :bonus_exercises, false, 0
    change_column_null :course_progresses, :selftest_dpoints, false, 0
    change_column_null :course_progresses, :selftest_exercises, false, 0

    change_table :course_progresses, bulk: true do |t|
      # Add default values
      t.change_default :visits, from: nil, to: 0
      t.change_default :main_dpoints, from: nil, to: 0
      t.change_default :main_exercises, from: nil, to: 0
      t.change_default :bonus_dpoints, from: nil, to: 0
      t.change_default :bonus_exercises, from: nil, to: 0
      t.change_default :selftest_dpoints, from: nil, to: 0
      t.change_default :selftest_exercises, from: nil, to: 0
    end
  end
  # rubocop:enable Rails/BulkChangeTable
end
