# frozen_string_literal: true

##
# Publish the user's LTI grade to the course service to be
# accounted for the course progress.
#
module Lti
  class PublishGradeJob < ApplicationJob
    queue_as :default

    def perform(grade_id)
      grade = Lti::Grade.find grade_id
      grade.publish!
    end
  end
end
