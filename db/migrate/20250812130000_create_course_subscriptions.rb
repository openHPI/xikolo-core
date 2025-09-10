# frozen_string_literal: true

class CreateCourseSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :course_subscriptions, id: :uuid, default: -> { 'uuid_generate_v7ms()' } do |t|
      t.uuid :user_id, null: false
      t.uuid :course_id, null: false

      t.timestamps
    end

    add_index :course_subscriptions, %i[user_id course_id], unique: true
    add_foreign_key :course_subscriptions, :users
    add_foreign_key :course_subscriptions, :courses
  end
end
