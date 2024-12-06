# frozen_string_literal: true

class AssignmentSubmission < Step
  before_save :update_item_submission_deadline

  def update_item_submission_deadline
    return if new_record?
    return unless deadline_changed?

    Xikolo.api(:course).value!.rel(:item).patch(
      {submission_deadline: deadline},
      {id: peer_assessment.item_id}
    ).value!
  end

  def completion(curr_user)
    # Binary decision whether or not a submitted submission exists
    exists = Submission.joins(:shared_submission).exists?(
      user_id: curr_user,
      shared_submissions: {peer_assessment_id:, submitted: true}
    )

    exists ? 1.0 : 0.0
  end

  def on_step_enter(user_id)
    # Create blank submission. Remember idempotency.
    submission_exists = Submission.joins(:shared_submission).exists?(
      user_id:,
      shared_submissions: {peer_assessment_id:}
    )
    unless submission_exists
      shared_submission = SharedSubmission.create! peer_assessment_id:, submitted: false
      participant = Participant.find_by(peer_assessment_id:, user_id:)
      ([user_id] + participant.group_members.pluck(:user_id)).each do |user|
        Submission.create!(user_id: user, shared_submission:)
      rescue ActiveRecord::RecordInvalid => e
        Mnemosyne.attach_error(e)
        Sentry.capture_exception(e)
      end
    end
  end

  # inherited
  def advance_team_to_step?
    true
  end
end
