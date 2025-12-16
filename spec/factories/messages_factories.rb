# frozen_string_literal: true

FactoryBot.define do
  factory :'news_service/message' do
    association :announcement, factory: :'news_service/announcement'
    creator_id { generate(:user_id) }
    translations do
      {
        'en' => {
          'subject' => 'English subject',
          'content' => 'Oh, you gonna like my news... **LG**',
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
  end
end
