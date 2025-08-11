# frozen_string_literal: true

class Admin::StatisticsController < Abstract::FrontendController
  def news
    authorize! 'global.dashboard.show'
    @nav = IconNavigationPresenter.new(
      items: PlatformDashboardNav.items_for(current_user)
    )
  end
end
