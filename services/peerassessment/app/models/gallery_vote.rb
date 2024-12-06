# frozen_string_literal: true

class GalleryVote < ApplicationRecord
  default_scope { order('created_at ASC') }
  belongs_to :shared_submission
  scope :by_submission, lambda {|submission_id|
    Submission.find(submission_id).shared_submission.gallery_votes
  }
end
