# frozen_string_literal: true

module Xikolo
  module PeerAssessment
    class AssignmentSubmission < Xikolo::PeerAssessment::Step
      service Xikolo::PeerAssessment::Client, path: 'assignment_submissions'

      include Xikolo::PeerAssessment::Concerns::AssignmentSubmission
    end
  end
end
