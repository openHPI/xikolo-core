# frozen_string_literal: true

FactoryBot.define do
  factory :helpdesk_ticket, class: 'Duplicated::HelpdeskTicket' do
    sequence(:title) {|n| "Problem #{n}" }
    report { 'Something is not working' }
    topic { 'course' }
    user_id
    mail { 'test@example.org' }
    language { 'en' }
    created_at { 3.days.ago }

    trait :today do
      created_at { 2.hours.ago }
    end
  end
end
