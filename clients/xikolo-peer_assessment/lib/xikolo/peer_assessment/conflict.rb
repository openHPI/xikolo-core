# frozen_string_literal: true

module Xikolo::PeerAssessment
  class Conflict < Acfs::Resource
    service Xikolo::PeerAssessment::Client, path: 'conflicts'
    include Xikolo::PeerAssessment::Concerns::Conflict

    attribute :id,                    :uuid
    attribute :reporter,              :uuid
    attribute :reason,                :string
    attribute :legitimate,            :boolean # @deprecated
    attribute :open,                  :boolean
    attribute :conflict_subject_id,   :uuid
    attribute :conflict_subject_type, :string
    attribute :comment,               :string
    attribute :teacher_comment,       :string
    attribute :peer_assessment_id,    :uuid
    attribute :accused,               :uuid
    attribute :created_at,            :date_time
    attribute :accused_team_members,  :list
  end
end
