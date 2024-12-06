# frozen_string_literal: true

##
# This controller allows to trigger an assignment for the enabled user tests in
# a given context.
class AssignmentsController < ApplicationController
  respond_to :json

  def create
    render json: {features: assignment.new_features}, status: :created
  rescue ActiveRecord::RecordNotFound
    render json: {features: {}}
  end

  private

  def assignment
    # The user test for this user will be finished by default,
    # manual handling / finishing needs to be reimplemented in this controller
    experiment.assign(params[:user_id], autofinish: true, exclude_groups:)
  end

  def experiment
    UserTest.active.find_by!(
      course_id: valid_course_ids,
      identifier: params[:identifier]
    )
  end

  def valid_course_ids
    [nil].tap do |ids|
      ids << params[:course_id] if params[:course_id]
    end
  end

  def exclude_groups
    params[:exclude_groups].presence || []
  end
end
