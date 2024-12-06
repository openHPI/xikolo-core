# frozen_string_literal: true

FactoryBot.define do
  factory :ticket, class: 'Helpdesk::Ticket' do
    sequence(:title) {|n| "Problem #{n}" }
    report { 'Something is not working' }
    topic { 'course' }
    course_id
    user_id
    mail { 'test@example.org' }
    language { 'en' }
    created_at { 3.days.ago }
    url { 'https://xikolo.de/broken_page' }

    trait :today do
      created_at { 2.hours.ago }
    end
  end
end
