# frozen_string_literal: true

module Xikolo::PeerAssessment::Concerns
  module Participant
    extend ActiveSupport::Concern

    included do
      validates :user_id, :peer_assessment_id, presence: true
    end
  end
end
