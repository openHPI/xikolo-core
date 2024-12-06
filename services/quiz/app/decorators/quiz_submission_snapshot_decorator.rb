# frozen_string_literal: true

class QuizSubmissionSnapshotDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      quiz_submission_id:,
      data:,
      loaded_data: data,
      updated_at:,
    }.as_json(opts)
  end
end
