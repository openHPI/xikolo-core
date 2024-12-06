# frozen_string_literal: true

class ReviewRatingWorker
  include Sidekiq::Job

  def perform(user_id, peer_assessment_id)
    submission = Submission
      .joins(:shared_submission)
      .find_by(user_id:,
        shared_submissions: {peer_assessment_id:})

    # Try to create the course result.
    # If this fails, it will raise an error and thus the worker will retry.
    submission.write_course_result if submission.present?
  end
end
