# frozen_string_literal: true

class PeerGrading < Step
  after_create :create_pool

  def schedule_deadline_workers
    workers = []
    deadline_worker_jids_will_change!

    workers << NoReviewsWorker.perform_at(schedule_time, peer_assessment_id, id)

    # If this step is the last one before the results, schedule the release worker
    if peer_assessment.steps[-2].id == id
      workers << ReleaseResultsWorker.perform_at(schedule_time, peer_assessment_id, id)
    end

    self.deadline_worker_jids = workers
  end

  def completion(user_id)
    # Ratio of finished and required reviews
    finished_reviews = Review.where user_id:, step_id: id, submitted: true
    finished_reviews = finished_reviews.not_suspended

    [finished_reviews.size / required_reviews.to_f, 1.0].min
  end

  def on_step_enter(user_id)
    if peer_assessment.training_step
      # Destroy any unfinished training reviews (may linger in rare cases where
      # the user aborted an additional sample training)
      Review.where(
        user_id:,
        step_id: peer_assessment.training_step.id,
        submitted: false
      ).delete_all
    end

    # Enter the submission into the pool and compute priority
    s = Submission.joins(:shared_submission).find_by(
      user_id:,
      shared_submissions: {peer_assessment_id:}
    )
    s.handle_grading_pool_entry
  end

  def create_pool
    ResourcePool.create! peer_assessment:, purpose: 'review'
  end

  # override
  def advance_team_to_step?
    # true if successor of assignment submission
    peer_assessment.reload.training_step.nil?
  end
end
