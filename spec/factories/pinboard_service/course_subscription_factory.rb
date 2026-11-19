# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/course_subscription', class: 'PinboardService::CourseSubscription' do
    transient do
      course_id { nil }
      user_id { nil }
    end

    # Set FK columns during build (before INSERT) since they're NOT NULL
    after(:build) do |instance, evaluator|
      instance.course_id = evaluator.course_id if evaluator.course_id
      instance.user_id = evaluator.user_id if evaluator.user_id
    end
  end
end
