# frozen_string_literal: true

class PlatformDashboardNav < MenuWithPermissions
  item 'admin.dashboard.nav.dashboard', 'chart-mixed',
    if: ->(user, _course) { user.allowed?('global.dashboard.show', context: :root) },
    route: :admin_dashboard

  item 'admin.dashboard.nav.news', 'satellite-dish',
    if: ->(user, _course) { user.allowed? 'global.dashboard.show', context: :root },
    route: :admin_statistics_news
end
