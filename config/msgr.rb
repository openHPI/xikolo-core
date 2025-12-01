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
