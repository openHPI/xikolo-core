# frozen_string_literal: true

module PinboardService
class QuestionNotifyJob < ApplicationJob # rubocop:disable Layout/IndentationWidth
  queue_as :default

  def perform(question, question_url)
    user = Xikolo.api(:account).value.rel(:user).get({id: question.user_id})
    course = Xikolo.api(:course).value.rel(:course).get({id: question.course_id}).value!

    thread_subscribers = question.subscriptions.pluck(:user_id)
    course_subscribers = CourseSubscription.where(course_id: question.course_id).pluck(:user_id)
    subscribers = (thread_subscribers + course_subscribers).uniq

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
      },
      public: true,
      course_id: question.course_id,
      link: question_url,
      subscribers: subscribers,
    }).value!
  end
end
end
