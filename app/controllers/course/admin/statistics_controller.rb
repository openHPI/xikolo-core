# frozen_string_literal: true

class Course::Admin::StatisticsController < Abstract::FrontendController
  include CourseContextHelper

  inside_course

  def activity
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def geo
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def news
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def pinboard
    raise AbstractController::ActionNotFound unless Xikolo.config.beta_features['teaching_team_pinboard_activity']

    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def social
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def referrer
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def item_visits
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def quiz
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def videos
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def downloads
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def rich_texts
    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run
  end

  def item_details
    authorize! 'course.item_stats.show'
    @course = the_course
    Acfs.run

    @item_stats_nav = ItemStats::ItemStatsPresenter.nav_elements(@course)
  end

  def hide_course_nav?
    true
  end

  private

  def auth_context
    the_course.context_id
  end
end
