# frozen_string_literal: true

class Conflict < ApplicationRecord
  belongs_to :conflict_subject, polymorphic: true, optional: true
  belongs_to :peer_assessment

  validates :reason, :reporter, presence: true
  validates :conflict_subject_type, inclusion: {
    in: %w[Review Submission],
    allow_nil: true,
    message: 'invalid',
  }

  default_scope { order(created_at: :asc) }

  after_create :trigger_grade_recomputation
  after_create :notify
  after_create :submit_review

  after_save :check_status

  def submit_review
    # If filed against a submission, submit its review to prevent it
    # from being cleaned up and to simplify the review handling
    return unless conflict_subject_type == 'Submission'

    review = Review.find_by!(
      user_id: reporter,
      submission_id: conflict_subject_id
    )

    # Skips validations and more importantly callbacks
    # rubocop:disable Rails/SkipsModelValidations
    review.update_column :submitted, true

    return if review.reload.submitted

    raise RuntimeError('Review with conflict could not be submitted')
  end

  def trigger_grade_recomputation
    # If the subject is a Review, trigger the grade re-computation
    if conflict_subject_type == 'Review'
      # TODO: Force submitted...
      # does not seem to work above, still requires investigation
      conflict_subject.update_column :submitted, true
      conflict_subject.submission.team_submissions.each do |submission|
        submission.grade.compute_grade(recompute: true)
      end
    end
  end
  # rubocop:enable all

  def notify
    data = {id:, timestamp: DateTime.now.in_time_zone}

    Msgr.publish(data, to: 'xikolo.peer_assessment.conflict.create')
  end

  def check_status
    return unless saved_change_to_open?
    return if open

    Msgr.publish({id:, timestamp: DateTime.now.in_time_zone},
      to: 'xikolo.peer_assessment.conflict.resolved')
  end
end
