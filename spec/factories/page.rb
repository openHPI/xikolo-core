# frozen_string_literal: true

FactoryBot.define do
  factory :page do
    sequence(:name) {|n| "page#{n}" }
    sequence(:title) {|n| "Page Title #{n}" }
    text { 'Lorem ipsum dolor sit *markdown*' }

    trait :english do
      locale { 'en' }
      title { 'English Title' }
      text { 'English Text' }
    end

    trait :german do
      locale { 'de' }
      title { 'Deutscher Titel' }
      text { 'Deutscher Text' }
    end
  end
end
