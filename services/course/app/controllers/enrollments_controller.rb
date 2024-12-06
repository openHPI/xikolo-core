# frozen_string_literal: true

class EnrollmentsController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  # List allowed filter parameters for #index here.
  rfc6570_params index: %i[
    course_id
    user_id
    learning_evaluation
    deleted
    current_course
    per_page
    proctored
  ]
  def index
    enrollments = Enrollment.all

    # eliminate enrollments from deleted courses
    enrollments = enrollments.left_joins(:course).where({courses: {deleted: false}})

    enrollments = enrollments.active unless params[:deleted] == 'true'

    if params[:course_id].present?
      enrollments.where! course_id: course.id
    end

    enrollments.where! user_id: params[:user_id] if params[:user_id].present?

    if params[:proctored].present?
      enrollments.where! proctored: params[:proctored]
    end

    if params[:completed].present?
      enrollments.where! completed: params[:completed]
    end

    enrollments = LearningEvaluation.by_params(params).call(enrollments)

    @course_filter = course_filter.current if params[:current_course].present?

    unless @course_filter.nil?
      course_ids = course_filter.select(:id)
      enrollments = enrollments.where(course_id: course_ids)
    end

    respond_with enrollments, include_completed_at:
      params[:course_id].present? && params[:user_id].present?
  end

  def show
    respond_with Enrollment.find params[:id]
  end

  def create
    respond_with Enrollment::Create.call(
      params.require(:user_id),
      course,
      params.permit(:created_at, :updated_at, :proctored)
    )
  end

  def update
    respond_with Enrollment::Update.call(params.require(:id),
      params.permit(:proctored, :completed))
  end

  def destroy
    enrollment = Enrollment.find params[:id]
    respond_with Enrollment::Delete.call enrollment
  end

  def max_per_page
    500
  end

  private

  def enrollment_params
    params.permit :course_id, :user_id, :proctored
  end

  def course
    Course.by_identifier(params.require(:course_id)).take!
  end

  def course_filter
    @course_filter ||= Course.all
  end
end
