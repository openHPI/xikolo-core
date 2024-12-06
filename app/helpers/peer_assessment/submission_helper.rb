# frozen_string_literal: true

module PeerAssessment::SubmissionHelper
  # Checks if either a text or files (or both) are provided in order to prevent
  def submission_ready?(submission)
    !submission.attachments.empty? || submission.text.present?
  end

  # Centralizes logic required to fetch submissions and their files
  # Params:
  #   files   - indicates whether or not attachments should be loaded from the file service
  #   owner   - indicates whether or not the requesting student must be the owner of the submission
  #   user_id - which user's submission should be fetched, the current user by default
  def fetch_submission(owner: true, user_id: nil)
    # Submission is a singular resource
    submission = pa_api.rel(:submissions).get(
      peer_assessment_id: the_assessment.id,
      user_id: user_id || current_user.id
    ).value&.first

    sideload_attachments submission, owner:
  end

  # Fetches a submission by id.
  # Params:
  #   files   - indicates whether or not attachments should be loaded from the file service (true by default)
  #   owner   - indicates whether or not the requesting student must be the owner of the submission (false by default)
  def submission_by_id(id)
    # Submission is a singular resource
    sideload_attachments pa_api.rel(:submission).get(id:).value
  end

  def sideload_attachments(submission, owner: false)
    if !submission.nil? && owner
      ensure_owner_or_permitted submission, 'peerassessment.submission.manage'
    end
    submission
  end

  def redirect_url
    if URI(request.referer).path.include? 'additional_attempt'
      additional_attempt_peer_assessment_step_submission_path
    else
      peer_assessment_step_submission_path
    end
  end
end
