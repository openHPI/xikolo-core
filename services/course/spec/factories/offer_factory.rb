# frozen_string_literal: true

FactoryBot.define do
  factory :offer, class: 'Duplicated::Offer' do
    association(:course)
  end
end
