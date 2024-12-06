# frozen_string_literal: true

FactoryBot.define do
  factory :alert do
    translations do
      {
        'en' => {
          'title' => 'Some title',
          'text' => 'A beautiful alert text',
        },
      }
    end

    trait :published do
      publish_at { 2.days.ago }
      publish_until { 2.days.from_now }
    end

    trait :past do
      publish_at { 1.week.ago }
      publish_until { 3.days.ago }
    end

    trait :future do
      publish_at { 1.week.from_now }
    end
  end
end
