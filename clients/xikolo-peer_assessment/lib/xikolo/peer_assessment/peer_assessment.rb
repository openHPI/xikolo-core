# frozen_string_literal: true

module Xikolo::PeerAssessment
  class PeerAssessment < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'peer_assessments'
    include Xikolo::PeerAssessment::Concerns::PeerAssessment

    attribute :id, :uuid
    attribute :title, :string
    attribute :resubmissions, :integer
    attribute :instructions, :string
    attribute :course_id, :uuid
    attribute :item_id, :uuid
    attribute :max_points, :integer
    attribute :usage_disclaimer, :string
    attribute :grading_hints, :string
    attribute :allow_gallery_opt_out, :boolean
    attribute :allowed_attachments, :integer, default: 0
    attribute :max_file_size, :integer
    attribute :allowed_file_types, :string
    attribute :attachments, :list
    attribute :gallery_entries, :list
    attribute :is_team_assessment, :boolean, default: false
  end
end
