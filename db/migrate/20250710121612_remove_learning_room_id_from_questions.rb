# frozen_string_literal: true

class RemoveLearningRoomIDFromQuestions < ActiveRecord::Migration[7.2]
  def up
    remove_index :questions, name: :learning_room_double_posting_index
    remove_index :questions, name: :course_double_posting_index
    remove_column :questions, :learning_room_id, :uuid
    add_index :questions, %i[course_id user_id title text_hash], unique: true, name: 'course_double_posting_index'
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
