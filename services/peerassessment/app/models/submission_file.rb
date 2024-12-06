# frozen_string_literal: true

class SubmissionFile < ApplicationRecord
  belongs_to :shared_submission

  validates :name, :user_id, :size, :storage_uri, :mime_type, presence: true
  validates :size, numericality: {only_integer: true, greater_than: 0}
end
