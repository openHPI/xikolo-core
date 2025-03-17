# frozen_string_literal: true

# Account routes
route 'xikolo.account.password_reset.notify', to: 'account#password_reset'
route 'xikolo.account.email.confirm', to: 'account#confirm_email'
route 'xikolo.web.account.sign_up', to: 'account#welcome_email'

# Announcements
route 'xikolo.news.announcement.create', to: 'announcement#create'

route 'xikolo.notification.notify', to: 'notification#notify'
route 'xikolo.notification.notify_announcement', to: 'notification#announcement'

# Enrollments
route 'xikolo.course.enrollment.create', to: 'welcome_mail#notify'

# Statistic emails
route 'xikolo.lanalytics.course_stats.calculate', to: 'course_stats#send_daily_mails'
