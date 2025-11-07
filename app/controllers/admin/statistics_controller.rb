# frozen_string_literal: true

class Admin::StatisticsController < Abstract::FrontendController
  def news
    authorize! 'global.dashboard.show'
    @nav = IconNavigationPresenter.new(
      items: PlatformDashboardNav.items_for(current_user)
    )

    @global_news_table_headers = [
      I18n.t('admin.statistics.news.news_title_header'),
      "#{I18n.t('admin.statistics.news.total_header')} / #{I18n.t('admin.statistics.news.success_header')} / " \
      "#{I18n.t('admin.statistics.news.error_header')} / #{I18n.t('admin.statistics.news.disabled_header')} / " \
      "#{I18n.t('admin.statistics.news.read_header')}",
      I18n.t('admin.statistics.news.date_sent_header'),
      I18n.t('admin.statistics.news.state_header'),
    ]
    @global_news_table_rows = Admin::Statistics::Announcements.call(course_id: nil)
  end
end
