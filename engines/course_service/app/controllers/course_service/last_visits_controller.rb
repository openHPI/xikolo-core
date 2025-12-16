# frozen_string_literal: true

module CourseService
class LastVisitsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder

  respond_to :json

  def show
    if params[:user_id].blank?
      return head(:not_found, content_type: 'text/plain')
    end

    enrollment = Enrollment.find_by(
      user_id: params[:user_id],
      course_id: params[:course_id]
    )

    return head(:not_found, content_type: 'text/plain') if enrollment.blank?

    respond_with enrollment.last_visit
  end

  def decorate(res)
    LastVisitDecorator.decorate res || Visit.new
  end
end
end
