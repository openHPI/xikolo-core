# frozen_string_literal: true

module Proctoring
  class RegistrationStatus
    def initialize(status)
      @status = status
    end

    attr_reader :status

    # Was there an error when contacting the proctoring vendor?
    def available?
      !@status.nil?
    end

    # When registration is complete, the learner may start a proctoring session.
    def complete?
      status == :complete
    end

    # The learner has registered with the vendor, but calibration is not finished yet.
    def pending?
      status == :pending
    end

    # The learner has not yet registered with the vendor, we should forward them.
    def required?
      status == :required
    end
  end
end
