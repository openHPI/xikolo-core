# frozen_string_literal: true

module Xikolo
  module PeerAssessment
    class SelfAssessment < Xikolo::PeerAssessment::Step
      service Xikolo::PeerAssessment::Client, path: 'self_assessments'

      include Xikolo::PeerAssessment::Concerns::SelfAssessment
    end
  end
end
