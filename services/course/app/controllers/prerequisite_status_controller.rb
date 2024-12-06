# frozen_string_literal: true

class PrerequisiteStatusController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder

  respond_to :json

  # List allowed parameters for #index here.
  rfc6570_params index: %i[user_id]
  def index
    if prerequisites.any? && status.fulfilled?
      EnrollmentGroupWorker.perform_async course.id, user_id
    end

    respond_with status
  end

  private

  def status
    @status ||= prerequisites.status_for(user_id)
  end

  def prerequisites
    course.prerequisites
  end

  def course
    Course.by_identifier(params[:id]).take!
  end

  def user_id
    params.require :user_id
  end
end
