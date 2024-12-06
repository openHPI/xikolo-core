# frozen_string_literal: true

class PlatformDashboardNav < MenuWithPermissions
  item 'admin.dashboard.nav.dashboard', 'chart-mixed',
    if: ->(user, _course) { user.allowed?('global.dashboard.show', context: :root) },
    route: :admin_dashboard

  item 'admin.dashboard.nav.courses', 'book',
    if: ->(user, _course) { user.allowed?('global.dashboard.show', context: :root) },
    route: :admin_statistics_courses

  item 'admin.dashboard.nav.activity', 'clock',
    if: ->(user, _course) { user.allowed? 'global.dashboard.show', context: :root },
    route: :admin_statistics_activity

  item 'admin.dashboard.nav.geo', 'map-location-dot',
    if: ->(user, _course) { user.allowed? 'global.dashboard.show', context: :root },
    route: :admin_statistics_geo

  item 'admin.dashboard.nav.news', 'satellite-dish',
    if: ->(user, _course) { user.allowed? 'global.dashboard.show', context: :root },
    route: :admin_statistics_news

  item 'admin.dashboard.nav.social', 'share-alt',
    if: ->(user, _course) { user.allowed? 'global.dashboard.show', context: :root },
    route: :admin_statistics_social

  item 'admin.dashboard.nav.referrer', 'external-link',
    if: ->(user, _course) { user.allowed? 'global.dashboard.show', context: :root },
    route: :admin_statistics_referrer
end
