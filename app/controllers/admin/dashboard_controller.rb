# frozen_string_literal: true

class Admin::DashboardController < Abstract::FrontendController
  def show
    authorize! 'global.dashboard.show'

    @nav = IconNavigationPresenter.new(
      items: PlatformDashboardNav.items_for(current_user)
    )

    @platform_learners_and_enrollments = Admin::Statistics::LearnersAndEnrollments.call
    @platform_certificates_counts = Certificate::Record.group(:type).count

    @age_distribution_table_rows = Admin::Statistics::AgeDistribution.call
    @age_distribution_table_headers = [
      t('admin.dashboard.show.age.table.age_group'),
      t('admin.dashboard.show.age.table.global_count'),
      t('admin.dashboard.show.age.table.global_share'),
    ]
  end
end
