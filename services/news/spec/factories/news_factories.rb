# frozen_string_literal: true

FactoryBot.define do
  factory :'news_service/news' do
    author_id { '00000000-0000-4444-9999-000000000000' }
    course_id { '00000000-0000-4444-9999-000000000000' }
    publish_at { 7.days.from_now }
    show_on_homepage { false }
    audience { nil }

    trait :global do
      course_id { nil }
    end

    trait :published do
      publish_at { 2.days.ago }
    end

    trait :read do
      transient do
        read_by_users { [generate(:user_id)] }
      end

      after(:create) do |news, evaluator|
        evaluator.read_by_users.each do |user_id|
          news.read_states.create(user_id:)
        end
      end
    end

    transient do
      teaser { '' }
      translations { true }
    end

    # Create default translation
    after(:create) do |news, evaluator|
      # Do not add default translation if disabled
      # via `translations: false`
      next unless evaluator.translations

      news.translations.create(
        title: 'Some title',
        text: 'A beautiful announcement text',
        teaser: evaluator.teaser,
        locale: 'en'
      )
    end

    trait :with_german_translation do
      after(:create) do |news, evaluator|
        news.translations.create(
          title: 'Deutscher Titel',
          text: 'Deutscher Text',
          teaser: evaluator.teaser,
          locale: 'de'
        )
      end
    end

    trait :with_many_lines do
      transient do
        num_lines { 0 }
        teaser { '' }
      end

      after(:create) do |news, evaluator|
        news.translations.first.update(text: "Line\n" * evaluator.num_lines)
      end
    end
  end
end
