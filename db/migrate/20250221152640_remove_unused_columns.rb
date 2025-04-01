# frozen_string_literal: true

class RemoveUnusedColumns < ActiveRecord::Migration[7.2]
  def change
    remove_column :records, :truerec_id, :integer if column_exists?(:records, :truerec_id)
    remove_column :enrollments, :role, :string if column_exists?(:enrollments, :role)
    remove_column :lti_exercises, :is_main_exercise, :boolean if column_exists?(:lti_exercises, :is_main_exercise)
    remove_column :lti_exercises, :is_bonus_exercise, :boolean if column_exists?(:lti_exercises, :is_bonus_exercise)
  end
end
