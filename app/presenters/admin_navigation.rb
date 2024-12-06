# frozen_string_literal: true

class AdminNavigation < MenuWithPermissions
  item 'header.navigation.admin.dashboard', 'chart-mixed',
    if: ->(user, _course) { user.allowed?('global.dashboard.show', context: :root) },
    route: :admin_dashboard

  item 'header.navigation.admin.courses', 'book',
    if: ->(user, _course) { user.allowed?('course.course.index', context: :root) },
    route: :admin_courses

  item 'header.navigation.admin.categories', 'boxes-stacked',
    if: ->(user, _course) { user.allowed?('course.cluster.index', context: :root) },
    route: :admin_clusters

  item 'header.navigation.admin.users', 'user',
    if: ->(user, _course) { user.allowed?('account.user.index', context: :root) },
    route: :users

  item 'header.navigation.admin.teachers', 'glasses',
    if: ->(user, _course) { user.allowed?('course.teacher.view', context: :root) },
    route: :teachers

  item 'header.navigation.admin.permissions', 'key',
    if: ->(user, _course) { user.allowed?('account.permissions.view', context: :root) },
    route: :permissions

  item 'header.navigation.admin.videos', 'film',
    if: ->(user, _course) { user.allowed?('video.video.manage', context: :root) },
    route: :videos

  item 'header.navigation.admin.lti_providers', 'laptop-code',
    if: ->(user, _course) { user.allowed? 'lti.provider.manage', context: :root },
    route: :admin_lti_providers

  item 'header.navigation.admin.knowledge_documents', 'file-lines',
    if: lambda {|user, _course|
      user.allowed?('course.document.manage', context: :root) &&
        Xikolo.config.beta_features['documents']
    },
    route: :documents

  item 'header.navigation.admin.channels', 'tags',
    if: ->(user, _course) { user.allowed?('course.channel.index', context: :root) },
    route: :admin_channels

  item 'header.navigation.admin.announcements', 'satellite-dish',
    if: lambda {|user, _course|
      user.feature?('admin_announcements') &&
        user.allowed?('news.announcement.create', context: :root)
    },
    route: :admin_announcements

  item 'header.navigation.admin.polls', 'square-poll-vertical',
    if: ->(user, _course) { user.allowed?('helpdesk.polls.manage', context: :root) },
    route: :admin_polls

  item 'header.navigation.admin.user_tests', 'flask',
    if: lambda {|user, _course|
      user.allowed?('grouping.user_test.index', context: :root) &&
        Xikolo.config.beta_features['show_user_tests']
    },
    route: :user_tests

  item 'header.navigation.admin.reports', 'file-zipper',
    if: ->(user, _course) { user.allowed?('lanalytics.report.create', context: :root) },
    route: :reports

  item 'header.navigation.admin.vouchers', 'tag',
    if: lambda {|user, _course|
      Xikolo.config.voucher['enabled'] && user.allowed?('course.vouchers.issue', context: :root)
    },
    route: :vouchers
end
