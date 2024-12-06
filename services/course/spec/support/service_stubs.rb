# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    Stub.service(
      :account,
      group_url: '/groups/{id}',
      groups_url: '/groups',
      membership_url: '/memberships/{id}',
      memberships_url: '/memberships',
      contexts_url: '/contexts',
      grants_url: '/grants',
      session_url: '/sessions/{id}',
      user_url: '/users/{id}'
    )

    Stub.service(
      :submission,
      user_quiz_attempts_url: '/user_quiz_attempts'
    )

    Stub.service(
      :quiz,
      quizzes_url: '/quizzes',
      quiz_url: '/quizzes/{id}',
      questions_url: '/questions',
      question_url: '/questions/{id}',
      answers_url: '/answers',
      answer_url: '/answers/{id}'
    )
  end
end
