# frozen_string_literal: true

module Xikolo
  module PeerAssessment
    class PeerGrading < Xikolo::PeerAssessment::Step
      service Xikolo::PeerAssessment::Client, path: 'peer_gradings'

      include Xikolo::PeerAssessment::Concerns::PeerGrading

      attribute :required_reviews, :integer
    end
  end
end
