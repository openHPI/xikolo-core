# frozen_string_literal: true

module CourseService
class PersistRankingTasksController < ApplicationController # rubocop:disable Layout/IndentationWidth
  # responders Responders::ApiResponder,
  #           Responders::DecorateResponder,
  #           Responders::HttpCacheResponder
  respond_to :json

  def create
    PersistRankingWorker.perform_async(course.id)

    render json: {course_id: course.id}, status: :created
  end

  private

  def course
    @course ||= Course.find params[:course_id]
  end
end
end
