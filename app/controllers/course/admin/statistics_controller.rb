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

    @announcements_table_rows = Admin::Statistics::Announcements.call(course_id: @course.id)
    @announcements_table_headers = [
      I18n.t('admin.statistics.news.news_title_header'),
      "#{I18n.t('admin.statistics.news.total_header')} / #{I18n.t('admin.statistics.news.success_header')} / " \
      "#{I18n.t('admin.statistics.news.error_header')} / #{I18n.t('admin.statistics.news.disabled_header')} / " \
      "#{I18n.t('admin.statistics.news.read_header')}",
      I18n.t('admin.statistics.news.date_sent_header'),
      I18n.t('admin.statistics.news.state_header'),
    ]
  end

  def pinboard
    raise AbstractController::ActionNotFound unless Xikolo.config.beta_features['teaching_team_pinboard_activity']

    authorize! 'course.dashboard.view'
    @course = the_course
    Acfs.run

    most_active = ::Admin::Statistics::MostActive.call(course_id: @course.id)
    @most_active_table_headers = [
      most_active[:headers][:user],
      most_active[:headers][:posts],
      most_active[:headers][:threads],
    ]

    @most_active_table_rows = most_active[:most_active_data].map do |row|
      {
        user: row['user'],
        posts: row['posts'],
        threads: row['threads'],
      }
    end
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

    result = Admin::Statistics::Videos.new(course_id: @course.id).call
    @course_code = @course['course_code']
    @videos_table_headers = result[:headers].values
    @videos_data = result[:videos_data]
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
