# frozen_string_literal: true

##
# Load the user's proctoring image to be printed on the
# certificate from SMOWL and upload it to S3.
#
# This job is supposed to be triggered after a user submits
# any proctored quiz. At this point, the user registration
# is valid. The job does not need to be triggered if the
# user image for a course already exists in S3.
#
module Proctoring
  class UploadCertificateImageJob < ApplicationJob
    queue_as :default
    queue_with_priority :eventual

    # On provider errors, we give them a bit of time before we retry, but also
    # limit the number of retries.
    retry_on Proctoring::ServiceError, wait: ->(executions) { executions.hours }, attempts: 10

    def perform(_enrollment_id); end
  end
end
