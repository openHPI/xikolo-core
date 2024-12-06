# frozen_string_literal: true

class Admin::DashboardController < Abstract::FrontendController
  def show
    authorize! 'global.dashboard.show'

    @nav = IconNavigationPresenter.new(
      items: PlatformDashboardNav.items_for(current_user)
    )
  end
end
