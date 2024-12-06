# frozen_string_literal: true

class RemoveSentimentalValueFromQuestions < ActiveRecord::Migration[6.0]
  def change
    remove_column :questions, :sentimental_value, :float
    remove_column :answers, :sentimental_value, :float
    remove_column :comments, :sentimental_value, :float
  end
end
