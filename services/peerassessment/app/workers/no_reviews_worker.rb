# frozen_string_literal: true

class NoReviewsWorker
  include Sidekiq::Job

  JOIN_SQL = <<~SQL.squish
    LEFT JOIN reviews ON reviews.submission_id = submissions.id AND reviews.step_id = ?
  SQL
  def perform(peer_assessment_id, grading_step_id)
    grading_step = PeerGrading.find grading_step_id
    submissions = Submission
      .joins(:shared_submission)
      .joins(ApplicationRecord.sanitize_sql_array([JOIN_SQL, grading_step_id]))
      .where(shared_submissions: {peer_assessment_id:})
      .where(reviews: {id: nil})

    grading_step.with_lock do
      # Clear up the worker id to allow rescheduling
      grading_step.deadline_worker_jids_will_change!
      grading_step.deadline_worker_jids.reject! {|rjid| rjid == jid }
      grading_step.save!
    end

    # Create a special conflict for these submissions
    submissions.each do |submission|
      # If no such conflict already exists
      # (idempotency and resumability of this job)
      next if Conflict.exists? \
        reason: 'no_reviews',
        peer_assessment_id: peer_assessment_id,
        reporter: submission.user_id

      # Check if the student is eligible to get a grade
      # (i.e. s/he reviewed the required amount of peers)
      next unless grading_step.completion(submission.user_id).to_d == BigDecimal(1)

      conflict = Conflict.create!(
        reason: 'no_reviews',
        peer_assessment_id:,
        reporter: submission.user_id,
        open: true,
        comment: 'Automatically generated report for this user: ' \
                 'A review is required since he got none from his peers.'
      )

      logger.info "Created no_reviews report with ID #{conflict.id} " \
                  "for user #{submission.user_id}."
    end
  end
end
