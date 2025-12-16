# frozen_string_literal: true

module CourseService
class EnrollmentDecorator < ApplicationDecorator # rubocop:disable Layout/IndentationWidth
  delegate_all
  def base(opts = {})
    attrs = {
      id:,
      user_id:,
      course_id:,
      created_at: created_at&.iso8601,
      updated_at: updated_at&.iso8601,
      proctored:,
      deleted:,
      forced_submission_date: forced_submission_date&.iso8601,
    }
    if %i[user_dpoints maximal_dpoints]
        .map {|method| model.has_attribute? method }.all? # learning evaluation
      attrs[:points] = {
        achieved: format_point(user_dpoints),
        maximal: format_point(maximal_dpoints),
        percentage: format_percentage(points_percentage),
      }
      attrs[:certificates] = {
        confirmation_of_participation:
          course.confirmation_of_participation?(model),
        record_of_achievement: course.record_of_achievement?(model),
        certificate: course.certificate?(model),
        transcript_of_records: course.transcript_of_records?(model),
      }
      attrs[:completed] = object.completed?
      attrs[:quantile] = object.effective_quantile
      attrs[:visits] = {
        visited: visits_visited.to_i,
        total: visits_total.to_i,
        percentage: format_percentage(visits_percentage),
      }
    end
    if opts.key?(:include_completed_at) && opts[:include_completed_at]
      attrs[:completed_at] = model.completed_at
    end
    attrs
  end

  def as_api_v1(opts = {})
    base(opts).merge \
      url: h.enrollment_path(model),
      reactivations_url: h.enrollment_reactivations_path(model)
  end

  def as_api_v2(_opts = {})
    {
      id:,
      user_id:,
      visits: {
        visited: visits_visited.to_i,
        total: visits_total.to_i,
        percentage: format_percentage(visits_percentage),
      },
      points: {
        achieved: format_point(user_dpoints),
        maximal: format_point(maximal_dpoints),
        percentage: format_percentage(points_percentage),
      },
      certificates: {
        confirmation_of_participation:
          object.course.confirmation_of_participation?(object),
        record_of_achievement: object.course.record_of_achievement?(object),
        certificate: object.course.certificate?(object),
      },
      completed: object.completed?,
      confirmed: true,
      reactivated: object.reactivated?,
    }
  end

  def as_event(opts = {})
    base(opts)
  end

  def user_dpoints
    model.user_dpoints || 0
  end

  def maximal_dpoints
    model.maximal_dpoints || 0
  end

  def format_point(value)
    (value / 10.0).to_f
  end

  def format_percentage(value)
    # Call to_d to use BigDecimal's more precise floating-point arithmetic and
    # to_f afterward for the correct final representation and to avoid string
    # conversion in some cases.
    value.to_d.floor(2).to_f
  end
end
end
