# frozen_string_literal: true

require 'quiz_submission_data_serializer'

class QuizSubmissionSnapshot < ApplicationRecord
  belongs_to :quiz_submission

  serialize :data, coder: QuizSubmissionDataSerializer
end
