# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/channel' do
    sequence(:code) {|n| "channel-#{n}" }
    title_translations { {'de' => 'Channel DE', 'en' => 'Channel EN'} }

    public { true }

    archived { false }

    trait :full_blown do
      description { {en: 'This is an awesome channel.'} }
      stage_statement { 'Just blabla.' }
      info_link do
        {
          'href' => {'en' => 'https://www.example.com/info', 'de' => 'https://www.example.com/de/info'},
          'label' => {'en' => 'Additional information', 'de' => 'Zusätzliche Informationen'},
        }
      end
    end
  end
end
