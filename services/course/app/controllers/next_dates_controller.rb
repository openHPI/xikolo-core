# frozen_string_literal: true

class NextDatesController < ApplicationController
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder
  respond_to :json
  def index
    dates = NextDate
      .active
      .for_user(params[:user_id])
      .where(course_id: course_filter)
      .order_by_date
      .includes(:course)
    if params[:resource_type].present?
      dates.where! resource_type: params[:resource_type]
    end
    dates.where! type: params[:type].split(',') if params[:type].present?
    respond_with dates
  end

  def course_filter
    return params[:course_id] if params[:course_id]

    if params[:user_id]
      Enrollment.unscoped.where(user_id: params[:user_id]).active
        .select(:course_id)
    else
      Course.unrestricted.where(hidden: false).select(:id)
    end
  end
end
