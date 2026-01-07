# frozen_string_literal: true

# Gamification: Award XP to users based on course and pinboard activity
route 'xikolo.pinboard.vote.create', to: 'gamification#vote_create'
route 'xikolo.pinboard.question.create', to: 'gamification#question_create'
route 'xikolo.pinboard.comment.create', to: 'gamification#comment_create'
route 'xikolo.pinboard.question.update', to: 'gamification#answer_accepted'
route 'xikolo.pinboard.answer.create', to: 'gamification#answer_create'
route 'xikolo.course.result.create', to: 'gamification#result_create'
route 'xikolo.course.visit.create', to: 'gamification#visit_create'

## Listen to course item changes
route 'xikolo.course.item.create', to: 'timeeffort_service/item#create_or_update'
route 'xikolo.course.item.update', to: 'timeeffort_service/item#create_or_update'
route 'xikolo.course.item.destroy', to: 'timeeffort_service/item#destroy'

## Listen to quiz question/answer changes
route 'xikolo.quiz.question.create', to: 'timeeffort_service/quiz#question_changed'
route 'xikolo.quiz.question.update', to: 'timeeffort_service/quiz#question_changed'
route 'xikolo.quiz.question.destroy', to: 'timeeffort_service/quiz#question_changed'
route 'xikolo.quiz.answer.create', to: 'timeeffort_service/quiz#answer_changed'
route 'xikolo.quiz.answer.update', to: 'timeeffort_service/quiz#answer_changed'

# Answers cannot be deleted via UI, but can be removed using a rake task
route 'xikolo.quiz.answer.destroy', to: 'timeeffort_service/quiz#answer_changed'

# PinboardService: Handle pinboard related messages
route 'xikolo.pinboard.read_question', to: 'pinboard_service/question#read_question'
route 'xikolo.course.course.update', to: 'pinboard_service/pinboard_search_course#update'

route 'xikolo.course.clone', to: 'course_service/course#clone'

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
