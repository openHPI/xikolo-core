# frozen_string_literal: true

class SharedSubmission < ApplicationRecord
  belongs_to :peer_assessment
  has_many :submissions
  has_many :gallery_votes
  has_many :files, -> { order(created_at: :asc) }, class_name: 'SubmissionFile'

  validate :ensure_unsubmitted, on: :update
  validate :ensure_timeliness,  on: :update
  validate :ensure_attachment_count, on: :update

  scope :by_submission, lambda {|submission_id|
    Submission.find(submission_id).shared_submission
  }

  ### Validation Methods and Callbacks ###

  def ensure_unsubmitted
    if submitted_was
      errors.add :base, 'You can not update a submitted submission'
    end
  end

  def ensure_timeliness
    # Check deadline of the assignment submission step, which is _always_ the first step
    if !peer_assessment || peer_assessment.steps.first.deadline.past?
      errors.add :base, 'The submission deadline passed.'
    end
  end

  def ensure_attachment_count
    if peer_assessment.allowed_attachments < files.size
      errors.add :attachments, 'You exceeded the allowed file count'
    end
  end
end
