# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    Stub.service(:account, build(:'account:root'))

    Stub.service(
      :submission,
      user_quiz_attempts_url: '/user_quiz_attempts'
    )

    Stub.service(:quiz, build(:'quiz:root'))
  end
end
