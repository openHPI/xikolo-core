# frozen_string_literal: true

##
# Load the user's proctoring results for a quiz from the proctoring vendor and
# store it in the vendor data attribute of the submission to reduce the amount
# of communication with the external vendor.
#
# This job is supposed to be triggered after learners submit solutions to
# proctored quizzes. At this point, the user registration is valid. We can also
# safely assume that the course and quiz item must have been proctored.
#
module Proctoring
  class StoreSubmissionResultsJob < ApplicationJob
    queue_as :default
    queue_with_priority :eventual

    # If there are (temporary?) service issues, give the provider some time.
    retry_on Proctoring::ServiceError, wait: ->(executions) { executions.hours }, attempts: 10

    retry_on ExpectedRetry, wait: 1.hour, attempts: 48

    def perform(submission_id)
      proctoring = Quiz::Submission.find(submission_id).proctoring

      # Do not overwrite data that has been stored already. For example,
      # if the features or their configuration (thresholds) on our side or
      # on the provider's side changes, we want to keep the proctoring
      # results from this point of time.
      return if proctoring.loaded?

      proctoring.load_from_vendor!
    rescue Quiz::Submission::Proctoring::VendorNotReady
      # Proctoring results not yet being ready is a frequent and expected
      # scenario. Raise an error to retry until the results are ready and can
      # be stored with the submission.
      raise ExpectedRetry.new 'Proctoring results not ready'
    end
  end
end
