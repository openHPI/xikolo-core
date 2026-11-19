# frozen_string_literal: true

class AddDisplayedQuestionCountToQuizzes < ActiveRecord::Migration[8.1]
  def change
    add_column :quizzes, :displayed_question_count, :integer
  end
end
