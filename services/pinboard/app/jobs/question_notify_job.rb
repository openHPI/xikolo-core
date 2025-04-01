# frozen_string_literal: true

class QuestionNotifyJob < ApplicationJob
  queue_as :default

  def perform(question, question_url)
    user = Xikolo.api(:account).value.rel(:user).get({id: question.user_id})
    course = Xikolo.api(:course).value.rel(:course).get({id: question.course_id}).value!

    collab_space = {}
    if question.learning_room_id.present?
      collab_space = Xikolo.api(:collabspace).value.rel(:collab_space).get({id: question.learning_room_id}).value!
    end

    Xikolo.api(:notification).value.rel(:events).post({
      key: question.discussion_flag ? 'pinboard.discussion.new' : 'pinboard.question.new',
      payload: {
        user_id: question.user_id,
          username: user.value!['name'],
          question_id: question.id,
          title: question.title,
          thread_title: question.title,
          text: question.text,
          course_code: course['course_code'],
          course_name: course['title'],
          learning_room_name: collab_space['name'],
      },
      public: question.learning_room_id.blank?,
      course_id: question.course_id,
      learning_room_id: question.learning_room_id,
      link: question_url,
      subscribers: question.subscriptions.pluck(:user_id),
    }).value!
  end
end
