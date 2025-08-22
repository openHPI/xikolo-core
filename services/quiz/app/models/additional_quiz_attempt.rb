# frozen_string_literal: true

class AdditionalQuizAttempt < ApplicationRecord
  validates :user_id, uniqueness: {scope: :quiz_id}

  default_scope -> { order(:created_at) }
end
