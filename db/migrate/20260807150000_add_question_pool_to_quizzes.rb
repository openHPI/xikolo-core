# frozen_string_literal: true

class AddQuestionPoolToQuizzes < ActiveRecord::Migration[8.1]
  def change
    add_column :quizzes, :question_pool, :boolean, default: false, null: false
  end
end
