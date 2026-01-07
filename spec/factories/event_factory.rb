# frozen_string_literal: true

FactoryBot.define do
  factory :'notification_service/event', class: 'NotificationService::Event' do
    key { 'news.announcement' }
    course_id
    public { true }
    payload do
      {
        link: '/fancy/url',
        user_name: 'Marc',
        course_title: nil,
        news_id: 'bb88f2f8-d1a5-40de-be18-496c6b576fe2',
        localized_title: '{"de":"katze", "en":"cat"}',
        text: 'Oh, you gonna like my news...',
      }
    end

    trait :not_public do
      public { false }
    end

    trait :with_notifications do
      transient do
        notify_user { [generate(:user_id)] }
      end

      after(:create) do |event, evaluator|
        Array(evaluator.notify_user).each do |user_id|
          event.notifications.create(user_id:)
        end
      end
    end
  end
end
