# frozen_string_literal: true

# Account routes
route 'xikolo.account.password_reset.notify', to: 'notification_service/account#password_reset'
route 'xikolo.account.email.confirm', to: 'notification_service/account#confirm_email'
route 'xikolo.web.account.sign_up', to: 'notification_service/account#welcome_email'

# Announcements
route 'xikolo.news.announcement.create', to: 'notification_service/announcement#create'

route 'xikolo.notification.notify', to: 'notification_service/notification#notify'
route 'xikolo.notification.notify_announcement', to: 'notification_service/notification#announcement'

# Enrollments
route 'xikolo.course.enrollment.create', to: 'notification_service/welcome_mail#notify'

# Statistic emails
route 'xikolo.lanalytics.course_stats.calculate', to: 'notification_service/course_stats#send_daily_mails'
