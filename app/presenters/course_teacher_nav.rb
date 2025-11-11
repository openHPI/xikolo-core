# frozen_string_literal: true

class CourseTeacherNav < MenuWithPermissions
  item(
    'courses.nav.teacher.dashboard', 'chart-mixed',
    if: ->(user, _course) { user.allowed? 'course.dashboard.view' },
    route: :course_dashboard
  ) do
    item 'courses.nav.teacher.item_visits', '',
      if: ->(user, _course) { user.allowed? 'course.dashboard.view' },
      route: :course_statistics_item_visits

    item 'courses.nav.teacher.videos', '',
      if: ->(user, _course) { user.allowed? 'course.dashboard.view' },
      route: :course_statistics_videos

    item 'courses.nav.teacher.item_details', '',
      if: ->(user, _course) { user.allowed? 'course.item_stats.show' },
      route: :course_statistics_item_details

    item 'courses.nav.teacher.forum_stats', '',
      if: lambda {|user, _course|
        user.allowed?('course.dashboard.view') &&
          Xikolo.config.beta_features['teaching_team_pinboard_activity']
      },
      route: :course_statistics_pinboard

    item 'courses.nav.teacher.geo', '',
      if: ->(user, _course) { user.allowed? 'course.dashboard.view' },
      route: :course_statistics_geo

    item 'courses.nav.teacher.announcements', '',
      if: ->(user, _course) { user.allowed? 'course.dashboard.view' },
      route: :course_statistics_news
  end

  item(
    'courses.nav.teacher.content', 'list-tree',
    if: ->(user, _course) { user.allowed? 'course.content.edit' },
    route: :course_sections
  ) do
    item 'courses.nav.teacher.lti', '',
      if: ->(user, _course) { user.allowed? 'course.content.edit' },
      route: :course_lti_providers

    item 'courses.nav.teacher.transpipe', '',
      if: ->(user, _course) { user.allowed?('video.subtitle.manage') && Transpipe.enabled? },
      route: ->(course) { Transpipe::URL.for_course course }
  end

  item(
    'courses.nav.teacher.settings', 'gear',
    if: ->(user, _course) { user.allowed? 'course.course.edit' },
    route: :edit_course
  ) do
    item 'courses.nav.teacher.visuals', '',
      if: ->(user, _course) { user.allowed? 'course.course.edit' },
      route: :edit_course_visual

    item 'courses.nav.teacher.permissions', '',
      if: ->(user, _course) { user.allowed? 'course.permissions.view' },
      route: :course_permissions

    item 'courses.nav.teacher.certificates', '',
      if: ->(user, _course) { user.allowed? 'certificate.template.manage' },
      route: :course_certificate_templates

    item 'courses.nav.teacher.metadata', '',
      if: ->(user, _course) { user.allowed? 'course.course.edit' },
      route: :edit_course_metadata

    item 'courses.nav.teacher.offers', '',
      if: ->(user, _course) { user.allowed? 'course.course.edit' },
      route: :course_offers
  end

  item 'courses.nav.teacher.enrollments', 'pen',
    if: ->(user, _course) { user.allowed? 'course.enrollment.index' },
    route: :course_enrollments

  item 'courses.nav.teacher.grading', 'money-check-pen',
    if: ->(user, _course) { user.allowed? 'quiz.submission.index' },
    route: :course_submissions

  item 'courses.nav.teacher.forum', 'comments',
    if: ->(user, _course) { user.allowed? 'pinboard.entity.block' },
    route: :course_abuse_reports
end
