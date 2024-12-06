# frozen_string_literal: true

module Xikolo
  module PeerAssessment
    class Results < Xikolo::PeerAssessment::Step
      service Xikolo::PeerAssessment::Client, path: 'results'

      include Xikolo::PeerAssessment::Concerns::Results
    end
  end
end
