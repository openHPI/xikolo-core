# frozen_string_literal: true

class SelfAssessment < Step
  def schedule_deadline_workers
    workers = []
    deadline_worker_jids_will_change!

    # If this step is the last one before the results, schedule the release worker
    if peer_assessment.steps[-2].id == id
      workers << ReleaseResultsWorker.perform_at(schedule_time, peer_assessment_id, id)
    end

    self.deadline_worker_jids = workers
  end

  def completion(curr_user)
    # Binary decision whether or not a submitted self-grading exists
    submission_id = Submission.joins(:shared_submission).find_by(
      user_id: curr_user,
      shared_submissions: {peer_assessment_id:}
    ).try(:id)

    return 0.0 if submission_id.nil?

    exists = Review.exists?(
      user_id: curr_user,
      submission_id:,
      submitted: true,
      step_id: id
    )
    exists ? 1.0 : 0.0
  end
end
