# frozen_string_literal: true

require 'quiz_submission_data_serializer'

class QuizSubmissionSnapshot < ApplicationRecord
  self.table_name = :quiz_submission_snapshots

  belongs_to :quiz_submission

  serialize :data, coder: QuizSubmissionDataSerializer
end
