# frozen_string_literal: true

# Gamification: Award XP to users based on course and pinboard activity
route 'xikolo.pinboard.vote.create', to: 'gamification#vote_create'
route 'xikolo.pinboard.question.create', to: 'gamification#question_create'
route 'xikolo.pinboard.comment.create', to: 'gamification#comment_create'
route 'xikolo.pinboard.question.update', to: 'gamification#answer_accepted'
route 'xikolo.pinboard.answer.create', to: 'gamification#answer_create'
route 'xikolo.course.result.create', to: 'gamification#result_create'
route 'xikolo.course.visit.create', to: 'gamification#visit_create'
