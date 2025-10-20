# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/channel', class: 'Channel' do
    sequence(:code) {|n| "channel-#{n}" }
    sequence(:name) {|n| "Channel #{n}" }

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
