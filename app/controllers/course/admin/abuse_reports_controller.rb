# frozen_string_literal: true

class Course::Admin::AbuseReportsController < Abstract::FrontendController
  include CourseContextHelper

  inside_course

  def index
    authorize! 'pinboard.entity.block'
    @abuse_reports = []

    Acfs.run # load course entities

    Xikolo.paginate(
      Xikolo.api(:pinboard).value!.rel(:abuse_reports).get(
        open: true,
        course_id: the_course.id
      )
    ) do |report|
      @abuse_reports << AbuseReportPresenter.new(report)
    end
  end

  def hide_course_nav?
    true
  end

  private

  def auth_context
    the_course.context_id
  end
end
