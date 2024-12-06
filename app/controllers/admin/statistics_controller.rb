# frozen_string_literal: true

class Admin::StatisticsController < Abstract::FrontendController
  def activity
    authorize! 'global.dashboard.show'
    @nav = dashboard_nav
  end

  def courses
    authorize! 'global.dashboard.show'
    @nav = dashboard_nav
    @courses = ::Admin::StatisticsPresenter.courses
  end

  def geo
    authorize! 'global.dashboard.show'
    @nav = dashboard_nav
  end

  def news
    authorize! 'global.dashboard.show'
    @nav = dashboard_nav
  end

  def social
    authorize! 'global.dashboard.show'
    @nav = dashboard_nav
  end

  def referrer
    authorize! 'global.dashboard.show'
    @nav = dashboard_nav
  end

  private

  def dashboard_nav
    IconNavigationPresenter.new(
      items: PlatformDashboardNav.items_for(current_user)
    )
  end
end
