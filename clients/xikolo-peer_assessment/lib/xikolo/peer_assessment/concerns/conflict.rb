# frozen_string_literal: true

module Xikolo::PeerAssessment::Concerns
  module Conflict
    extend ActiveSupport::Concern

    included do
      validates :reason, :reporter, :peer_assessment_id, presence: true
    end
  end
end
