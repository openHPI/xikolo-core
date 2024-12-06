# frozen_string_literal: true

FactoryBot.define do
  factory :announcement do
    author_id { generate(:user_id) }
    translations do
      {
        'en' => {
          'subject' => 'English Subject',
          'content' => 'Oh, you gonna like my news...',
        },
      }
    end

    trait :with_german_translation do
      translations do
        {
          'en' => {
            'subject' => 'English subject',
            'content' => 'Oh, you gonna like my news...',
          },
          'de' => {
            'subject' => 'Deutscher Titel',
            'content' => 'Das sind interessante News...',
          },
        }
      end
    end

    trait :german_only do
      translations do
        {
          'de' => {
            'subject' => 'Deutscher Titel',
            'content' => 'Das sind interessante News...',
          },
        }
      end
    end

    trait :with_message do
      after(:create) do |announcement, _evaluator|
        create(:message,
          announcement:,
          translations: announcement.translations,
          creator_id: announcement.author_id)
      end
    end

    trait :with_url_in_content do
      translations do
        {
          'en' => {
            'subject' => 'English Subject',
            'content' => 'Oh, click on https://www.example.com',
          },
        }
      end
    end
  end
end
