# frozen_string_literal: true

module CourseService
class ReactivationsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder

  respond_to :json

  def create
    if forbid_because_running?
      error! errors: {submission_date: 'running'}
      return
    end

    respond_with Enrollment::Reactivate.call(enrollment, submission_date)
  end

  private

  def forbid_because_running?
    # Unless we explicitly want to extend the reactivation, we only complain if
    # there is already an active reactivation
    enrollment.reactivated? && !params.key?(:extend)
  end

  def submission_date
    Time.iso8601 params.fetch :submission_date
  rescue ArgumentError
    error! errors: {submission_date: 'invalid'}
  end

  def enrollment
    @enrollment ||= Enrollment.find params.fetch :enrollment_id
  end
end
end
