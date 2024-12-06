# frozen_string_literal: true

class AddEvaluationDataToCourseProgresses < ActiveRecord::Migration[5.2]
  def change
    # The data is not used for reading anywhere yet and can be regenerated. That way, we avoid
    # invalid null values for existing records when adding the not null constraints during the
    # upgrade of our production VMs.
    up_only { execute 'TRUNCATE course_progresses' }

    change_table :course_progresses, bulk: true do |t|
      t.column :max_dpoints, :integer, default: 0, null: false
      t.column :max_visits, :integer, default: 0, null: false
      t.column :points_percentage_fpoints, :integer, default: 0, null: false
      t.column :visits_percentage_fpoints, :integer, default: 0, null: false
    end
  end
end
