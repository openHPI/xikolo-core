# frozen_string_literal: true

module Xikolo::PeerAssessment
  class SharedSubmission < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'shared_submissions'

    attribute :id,                  :uuid
    attribute :peer_assessment_id,  :uuid
    attribute :text,                :string
    attribute :submitted,           :boolean
    attribute :disallowed_sample,   :boolean
    attribute :gallery_opt_out,     :boolean
    attribute :attachments,         :list
    attribute :additional_attempts, :integer
    attribute :created_at,          :date_time
    attribute :updated_at,          :date_time
    attribute :submission_ids,      :list
  end
end
