# frozen_string_literal: true

module Xikolo::PeerAssessment::Concerns
  module Step
    extend ActiveSupport::Concern

    included do
      validates :position, :peer_assessment_id, presence: true
    end
  end
end
