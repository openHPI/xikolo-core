# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/cluster' do
    sequence(:id) {|n| "category-#{n}" } # rubocop:disable FactoryBot/IdSequence
    sequence(:translations) {|n| {'en' => "Category #{n}", 'de' => "Kategorie #{n}"} }
    sort_mode { 'automatic' }
  end
end
