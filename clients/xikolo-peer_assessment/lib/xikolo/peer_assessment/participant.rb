# frozen_string_literal: true

module Xikolo
  module PeerAssessment
    class Participant < Acfs::Resource
      service Xikolo::PeerAssessment::Client, path: 'participants'
      include Xikolo::PeerAssessment::Concerns::Participant

      attribute :id,                 :uuid
      attribute :user_id,            :uuid
      attribute :expertise,          :integer
      attribute :current_step,       :uuid   # Computed
      attribute :completion,         :float  # Computed
      attribute :grading_weight,     :float
      attribute :peer_assessment_id, :uuid
    end
  end
end
