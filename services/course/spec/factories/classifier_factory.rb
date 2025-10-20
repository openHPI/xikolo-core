# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/classifier', class: 'Classifier' do
    association :cluster, factory: :'course_service/cluster'
    sequence(:title) {|n| "Database Track #{n}" }
    sequence(:translations) {|n| {'en' => "Classifier ##{n}", 'de' => "Klassifikation ##{n}"} }
    sequence(:descriptions) {|n| {'en' => "Classifier Description ##{n}", 'de' => "Klassifikations-Beschreibung ##{n}"} }
    sequence(:position) {|i| i }
  end
end
