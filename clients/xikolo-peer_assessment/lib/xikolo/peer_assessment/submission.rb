# frozen_string_literal: true

module Xikolo::PeerAssessment
  class Submission < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'submissions'
    include Xikolo::PeerAssessment::Concerns::Submission

    attr_accessor :user

    attribute :id,                  :uuid
    attribute :peer_assessment_id,  :uuid
    attribute :text,                :string
    attribute :user_id,             :uuid
    attribute :submitted,           :boolean
    attribute :disallowed_sample,   :boolean
    attribute :gallery_opt_out,     :boolean
    attribute :attachments,         :list
    attribute :grade,               :uuid
    attribute :additional_attempts, :integer

    # These will only matter in the submission management section and can be
    # requested via "include_votes: true" parameter
    attribute :votes,              :integer
    attribute :average_votes,      :float
    attribute :nominations,        :integer

    attribute :created_at,         :date_time
    attribute :updated_at,         :date_time
    attribute :shared_submission_id, :uuid
  end
end
