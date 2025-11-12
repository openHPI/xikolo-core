# frozen_string_literal: true

route 'xikolo.pinboard.read_question', to: 'pinboard_service/question#read_question'

route 'xikolo.course.course.update', to: 'pinboard_service/pinboard_search_course#update'
