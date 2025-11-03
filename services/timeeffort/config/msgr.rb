# frozen_string_literal: true

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
