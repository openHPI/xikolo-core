# frozen_string_literal: true

class RemoveAnswerPredicationFromAnswers < ActiveRecord::Migration[6.0]
  def change
    remove_column :answers, :answer_prediction, :float
    remove_column :questions, :use_sorting, :integer
  end
end
