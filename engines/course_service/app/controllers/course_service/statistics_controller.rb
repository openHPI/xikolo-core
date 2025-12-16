# frozen_string_literal: true

module CourseService
class StatisticsController < ApplicationController # rubocop:disable Layout/IndentationWidth
  responders Responders::ApiResponder,
    Responders::DecorateResponder,
    Responders::HttpCacheResponder,
    Responders::PaginateResponder

  respond_to :json

  def show
    course = Course.find(params[:course_id])
    enrollments = course.enrollments
    current_enrollments = enrollments.active
    respond_with(
      course_id: course.id,
      enrollments: enrollments.count + course.enrollment_delta,
      current_enrollments: current_enrollments.count + course.enrollment_delta,
      last_day_enrollments: enrollments.created_last_day.count,
      last_7days_enrollments: enrollments.created_last_7days.count
    )
  end

  rfc6570_params enrollment_stats: %i[start_date end_date classifier_id]
  def enrollment_stats
    start_date = params[:start_date]
    end_date = params[:end_date]
    classifier_id = params[:classifier_id]

    enrollments = Enrollment.where(created_at: Time.zone.parse(start_date)..)

    if classifier_id.present?
      course_ids = Course.from('embed_courses AS courses')
        .not_deleted.by_classifier(classifier_id).ids
      enrollments = enrollments.where(course_id: course_ids)
    end

    enrollments = enrollments.where(created_at: ...Time.zone.parse(end_date))

    respond_with \
      total_enrollments: enrollments.count,
      unique_enrolled_users: enrollments.select('distinct user_id').count
  end
end
end
