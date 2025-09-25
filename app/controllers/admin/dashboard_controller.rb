# frozen_string_literal: true

class Admin::DashboardController < Abstract::FrontendController
  def show
    authorize! 'global.dashboard.show'

    @nav = IconNavigationPresenter.new(
      items: PlatformDashboardNav.items_for(current_user)
    )

    @age_distribution_table_rows = Admin::Statistics::AgeDistribution.call
    @age_distribution_table_headers = [
      t('admin.dashboard.show.age.table.age_group'),
      t('admin.dashboard.show.age.table.global_count'),
      t('admin.dashboard.show.age.table.global_share'),
    ]

    @client_usage_table_rows = Admin::Statistics::ClientUsage.call
    @client_usage_table_headers = [
      t('admin.dashboard.show.client_usage.table.client_types'),
      t('admin.dashboard.show.client_usage.table.users'),
      t('admin.dashboard.show.client_usage.table.share'),
    ]
  end
end
