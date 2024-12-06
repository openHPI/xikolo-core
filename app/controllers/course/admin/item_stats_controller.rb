# frozen_string_literal: true

class Course::Admin::ItemStatsController < Abstract::FrontendController
  include CourseContextHelper

  inside_course
  require_permission 'course.item_stats.show'

  def show
    @item_stats = ItemStats::ItemStatsPresenter.for(
      course_api.rel(:item).get(
        id: UUID4(params[:item_id]).to_s
      ).value!
    )

    Acfs.run
  end

  def hide_course_nav?
    true
  end

  private

  def auth_context
    the_course.context_id
  end

  def course_api
    @course_api ||= Xikolo.api(:course).value!
  end
end
