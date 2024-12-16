# frozen_string_literal: true

class AbuseReportsController < ApplicationController
  responders Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def index
    abuse_reports = AbuseReport.all
    abuse_reports = abuse_reports.open_reportables if params[:open]
    abuse_reports.where! course_id: params[:course_id] if params[:course_id]
    abuse_reports.order! 'created_at DESC'
    respond_with abuse_reports
  end

  def show
    respond_with AbuseReport.find params[:id]
  end

  def create
    respond_with AbuseReport
      .create_with(
        abuse_report_params.to_h.merge(course_id: reportable.course_ident)
      ).find_or_create_by!(
        reportable:,
        user_id: abuse_report_params[:user_id]
      )
  rescue ActiveRecord::RecordNotUnique
    # Handle possible race condition in find_or_create_by!
    retry
  rescue InvalidReportable
    error(404, json: {error: 'invalid reportable_id or reportable_type'})
  end

  private

  class InvalidReportable < RuntimeError; end

  def reportable
    @reportable ||= params[:reportable_type].constantize.find(params[:reportable_id])
  rescue NameError, ActiveRecord::RecordNotFound
    raise InvalidReportable
  end

  def abuse_report_params
    params.permit :reportable_type, :user_id, :url
  end
end
