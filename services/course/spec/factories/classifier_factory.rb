# frozen_string_literal: true

FactoryBot.define do
  factory :classifier do
    association :cluster
    sequence(:title) {|n| "Database Track #{n}" }
    sequence(:translations) {|n| {'en' => "Classifier ##{n}", 'de' => "Klassifikation ##{n}"} }
    sequence(:descriptions) {|n| {'en' => "Classifier Description ##{n}", 'de' => "Klassifikations-Beschreibung ##{n}"} }
    sequence(:position) {|i| i }
  end
end
