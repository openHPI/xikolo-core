# frozen_string_literal: true

module QuizService
class UserQuizAttemptsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  include UserQuizAttemptsHelper

  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  # Requires user_id and quiz_id as params
  # Builds UserQuizAttempts object with aggregation of current submissions
  # for the quiz with params[:quiz_id] and this user with user id params[:user_id]
  # If existent, adds additional attempts
  # Uses Integer(param) instead param.to_i to throw exception if param
  # is not set or not numeric
  def show
    if params[:user_id].present? && params[:quiz_id].present?
      # TODO: Use singleton for not having to wrap single item into collection
      respond_with UserQuizAttempts.new(user_id: params[:user_id], quiz_id: params[:quiz_id])
    else
      error 422, json: {}
    end
  end

  # Requires user_id and quiz_id to be passed
  # Used for updating / creating additional attempts for user for a quiz
  def create
    user_id = UUID(params[:user_id])

    if params[:course_id].present?
      UnlockCourseAssignmentsWorker.perform_async(UUID(params[:course_id]).to_s, user_id.to_s)
      render status: :accepted, json: {msg: 'All assignments will be unlocked'}
    elsif grant_additional_attempt(user_id, UUID(params[:quiz_id]), params[:additional_attempts])
      head :no_content
    end
  rescue TypeError
    error 400, plain: 'user_id and (quiz_id or course_id) must all be passed as UUID'
  rescue ArgumentError
    error 400, plain: 'additional_attempts must be passed as integer'
  end
end
end
