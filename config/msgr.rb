# frozen_string_literal: true

# Gamification: Award XP to users based on course and pinboard activity
route 'xikolo.pinboard.vote.create', to: 'gamification#vote_create'
route 'xikolo.pinboard.question.create', to: 'gamification#question_create'
route 'xikolo.pinboard.comment.create', to: 'gamification#comment_create'
route 'xikolo.pinboard.question.update', to: 'gamification#answer_accepted'
route 'xikolo.pinboard.answer.create', to: 'gamification#answer_create'
route 'xikolo.course.result.create', to: 'gamification#result_create'
route 'xikolo.course.visit.create', to: 'gamification#visit_create'

# PinboardService: Handle pinboard related messages
route 'xikolo.pinboard.read_question', to: 'pinboard_service/question#read_question'
route 'xikolo.course.course.update', to: 'pinboard_service/pinboard_search_course#update'

route 'xikolo.course.clone', to: 'course_service/course#clone'

# Announcements
route 'xikolo.news.announcement.create', to: 'notification_service/announcement#create'

route 'xikolo.notification.notify', to: 'notification_service/notification#notify'
route 'xikolo.notification.notify_announcement', to: 'notification_service/notification#announcement'

# Enrollments
route 'xikolo.course.enrollment.create', to: 'notification_service/welcome_mail#notify'

# Statistic emails
route 'xikolo.lanalytics.course_stats.calculate', to: 'notification_service/course_stats#send_daily_mails'
