# frozen_string_literal: true

require 'acfs'

module Xikolo
  module PeerAssessment
    require 'xikolo/peer_assessment/client'

    module Concerns
      require 'xikolo/peer_assessment/concerns/peer_assessment'
      require 'xikolo/peer_assessment/concerns/step'
      require 'xikolo/peer_assessment/concerns/assignment_submission'
      require 'xikolo/peer_assessment/concerns/peer_grading'
      require 'xikolo/peer_assessment/concerns/self_assessment'
      require 'xikolo/peer_assessment/concerns/results'
      require 'xikolo/peer_assessment/concerns/training'
      require 'xikolo/peer_assessment/concerns/submission'
      require 'xikolo/peer_assessment/concerns/review'
      require 'xikolo/peer_assessment/concerns/rubric'
      require 'xikolo/peer_assessment/concerns/rubric_option'
      require 'xikolo/peer_assessment/concerns/participant'
      require 'xikolo/peer_assessment/concerns/conflict'
      require 'xikolo/peer_assessment/concerns/grade'
    end

    require 'xikolo/peer_assessment/peer_assessment'
    require 'xikolo/peer_assessment/step'
    require 'xikolo/peer_assessment/assignment_submission'
    require 'xikolo/peer_assessment/peer_grading'
    require 'xikolo/peer_assessment/self_assessment'
    require 'xikolo/peer_assessment/results'
    require 'xikolo/peer_assessment/training'
    require 'xikolo/peer_assessment/submission'
    require 'xikolo/peer_assessment/shared_submission'
    require 'xikolo/peer_assessment/review'
    require 'xikolo/peer_assessment/statistic'
    require 'xikolo/peer_assessment/rubric'
    require 'xikolo/peer_assessment/rubric_option'
    require 'xikolo/peer_assessment/participant'
    require 'xikolo/peer_assessment/group'
    require 'xikolo/peer_assessment/conflict'
    require 'xikolo/peer_assessment/grade'
    require 'xikolo/peer_assessment/gallery_vote'
    require 'xikolo/peer_assessment/note'
  end
end
