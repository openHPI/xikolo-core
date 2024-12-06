# frozen_string_literal: true

module Xikolo::Submission
  class QuizSubmissionSnapshot < Acfs::Resource
    service Xikolo::Submission::Client, path: 'quiz_submission_snapshots'

    attribute :id, :uuid
    attribute :quiz_submission_id, :uuid
    attribute :data, :string
    attribute :loaded_data, :dict
    attribute :updated_at, :string
  end
end
