# frozen_string_literal: true

class RemoveLearningRoomIDFromTags < ActiveRecord::Migration[7.2]
  def up
    remove_index :tags, name: :learning_room_duplicate_tags_index
    remove_index :tags, name: :course_duplicate_tags_index
    remove_column :tags, :learning_room_id, :uuid
    add_index :tags, 'course_id, lower((name)::text)', name: 'course_duplicate_tags_index', unique: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
