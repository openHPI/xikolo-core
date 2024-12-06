# frozen_string_literal: true

module Xikolo::PeerAssessment::Concerns
  module Rubric
    extend ActiveSupport::Concern

    included do
      validates :peer_assessment_id, :title, presence: true
    end
  end
end
