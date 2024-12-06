# frozen_string_literal: true

class QuizSubmissionDecorator < Draper::Decorator
  delegate_all

  def as_json(opts = {})
    {
      id:,
      course_id:,
      quiz_id:,
      quiz_access_time:,
      quiz_submission_time:,
      quiz_version_at:,
      user_id:,
      submitted:,
      points:,
      snapshot_id: quiz_submission_snapshot.nil? ? nil : quiz_submission_snapshot.id,
      fudge_points:,
      question_count:,
      vendor_data:,
      url: h.quiz_submission_path(id),
      snapshots_url: h.quiz_submission_snapshots_path(quiz_submission_id: id),
    }.tap do |submission|
      if submission[:snapshot_id]
        submission[:snapshot_url] = h.quiz_submission_snapshot_path(submission[:snapshot_id])
      end
    end.as_json(opts)
  end
end
