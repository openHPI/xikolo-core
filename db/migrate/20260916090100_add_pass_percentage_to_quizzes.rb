# frozen_string_literal: true

class AddPassPercentageToQuizzes < ActiveRecord::Migration[8.1]
  def change
    add_column :quizzes, :pass_percentage, :integer, default: 70
  end
end
