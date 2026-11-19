# frozen_string_literal: true

class AddPositionToQuizSubmissionQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :quiz_submission_questions, :position, :integer
  end
end
