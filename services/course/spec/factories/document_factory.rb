# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/document', class: 'Document' do
    sequence(:title) {|i| "Document Title #{i}" }
    sequence(:description) {|j| "Document Description #{j}" }
    tags { ['git'] }

    public { true }

    deleted { false }

    trait :with_localizations do
      after(:create) do |document|
        document.localizations <<
          FactoryBot.create(:'course_service/document_localization', document_id: document.id, title: 'first', language: 'de')
        document.localizations <<
          FactoryBot.create(:'course_service/document_localization', document_id: document.id, title: 'second', language: 'en')
      end
    end

    trait :english do
      after(:create) do |document|
        document.localizations <<
          FactoryBot.create(:'course_service/document_localization', document_id: document.id, title: 'English', language: 'en')
      end
    end

    trait :german do
      after(:create) do |document|
        document.localizations <<
          FactoryBot.create(:'course_service/document_localization', document_id: document.id, title: 'Deutsch', language: 'de')
      end
    end

    trait :with_tag_a do
      tags { ['tag_a'] }
    end

    trait :with_tag_b do
      tags { ['tag_b'] }
    end

    trait :with_courses do
      after(:create) do |document|
        document.courses << FactoryBot.create(:'course_service/course')
      end
    end
  end
end
