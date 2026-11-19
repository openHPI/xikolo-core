# frozen_string_literal: true

class AdminNavigation < MenuWithPermissions
  item 'header.navigation.admin.dashboard', 'chart-mixed',
    if: ->(user, _course) { user.allowed?('global.dashboard.show') },
    route: :admin_dashboard

  item 'header.navigation.admin.courses', 'book',
    if: ->(user, _course) { user.allowed?('course.course.index') },
    route: :admin_courses

  item 'header.navigation.admin.shorts', 'video',
    if: ->(user, _course) { user.allowed?('course.short.index') },
    route: :admin_shorts

  item 'header.navigation.admin.categories', 'boxes-stacked',
    if: ->(user, _course) { user.allowed?('course.cluster.index') },
    route: :admin_clusters

  item 'header.navigation.admin.users', 'user',
    if: ->(user, _course) { user.allowed?('account.user.index') },
    route: :users

  item 'header.navigation.admin.teachers', 'glasses',
    if: ->(user, _course) { user.allowed?('course.teacher.view') },
    route: :teachers

  item 'header.navigation.admin.permissions', 'key',
    if: ->(user, _course) { user.allowed?('account.permissions.view') },
    route: :permissions

  item 'header.navigation.admin.videos', 'film',
    if: ->(user, _course) { user.allowed?('video.video.manage') },
    route: :videos

  item 'header.navigation.admin.lti_providers', 'laptop-code',
    if: ->(user, _course) { user.allowed? 'lti.provider.manage' },
    route: :admin_lti_providers

  item 'header.navigation.admin.channels', 'tags',
    if: ->(user, _course) { user.allowed?('course.channel.index') },
    route: :admin_channels

  item 'header.navigation.admin.announcements', 'satellite-dish',
    if: lambda {|user, _course|
      user.feature?('admin_announcements') &&
        user.allowed?('news.announcement.create')
    },
    route: :admin_announcements

  item 'header.navigation.admin.news', 'newspaper',
    if: ->(user, _course) { user.allowed?('course.course.index') },
    route: :news_index

  item 'header.navigation.admin.vouchers', 'tag',
    if: lambda {|user, _course|
      Xikolo.config.voucher['enabled'] && user.allowed?('course.vouchers.issue')
    },
    route: :vouchers
end
