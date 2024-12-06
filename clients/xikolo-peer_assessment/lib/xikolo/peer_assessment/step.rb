# frozen_string_literal: true

module Xikolo
  module PeerAssessment
    class Step < Acfs::Resource
      service Xikolo::PeerAssessment::Client, path: 'steps'
      include Xikolo::PeerAssessment::Concerns::Step

      attribute :id,                 :uuid
      attribute :peer_assessment_id, :uuid
      attribute :optional,           :boolean
      attribute :deadline,           :date_time
      attribute :position,           :integer
      attribute :open,               :boolean
      attribute :unlock_date,        :date_time
    end
  end
end
