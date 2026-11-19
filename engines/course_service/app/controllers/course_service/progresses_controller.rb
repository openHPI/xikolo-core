# frozen_string_literal: true

module CourseService
class ProgressesController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json
  def index
    # verify params
    unless params[:course_id].present? && params[:user_id].present?
      return head(:not_found, content_type: 'text/plain')
    end

    course = Course.by_identifier(params[:course_id]).take!
    progresses = Progresses.new(course, params[:user_id]).to_a

    # decorate
    respond_with progresses
  end

  def decorate(res)
    ProgressDecorator.decorate_collection res
  end
end
end
