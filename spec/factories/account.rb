# frozen_string_literal: true

require 'xikolo/common/rspec'

FactoryBot.define do
  factory :user, class: 'Account::User' do
    id { generate(:user_id) }
    sequence(:full_name) {|n| "User Fullname #{n}" }
    sequence(:display_name) {|n| "User Displayname #{n}" }
    language { 'en' }

    trait :with_email do
      after(:create) do |user|
        create(:email, :confirmed, :primary, user:)
        user.primary_email.reload
      end
    end

    trait :archived do
      archived { true }
      full_name { 'Deleted User' }
      display_name { 'Deleted User' }
      avatar_uri { nil }

      after(:create) do |user|
        user.update! confirmed: false
        user.emails.destroy_all
      end
    end
  end

  factory :session, class: 'Account::Session' do
    user
  end

  factory :authorization, class: 'Account::Authorization' do
    id { generate(:uuid) }
    user { :user }
    sequence(:uid) {|_n| generate(:uuid) }
  end

  factory :group, class: 'Account::Group' do
    transient do
      course { :course }
      member { nil }
    end

    name { "course.#{course.course_code}.students" }

    after(:create) do |group, evaluator|
      next unless evaluator.member

      group.memberships.create(user_id: evaluator.member)
    end
  end

  factory :membership, class: 'Account::Membership' do
    group
    user_id
  end

  factory 'account:session', class: Hash do
    id { generate(:uuid) }

    initialize_with { attributes.as_json }
  end

  factory 'account:user', class: Hash do
    id { generate(:user_id) }
    sequence(:full_name) {|n| "User Fullname #{n}" }
    sequence(:display_name) {|n| "User Displayname #{n}" }
    language { 'en' }
    sequence(:email) {|n| "eMail#{n}@openhpi.de" }

    url { "/account_service/users/#{id}" }
    consents_url { stub_url(:account, "/users/#{id}/consents") }
    emails_url { stub_url(:account, "/users/#{id}/emails") }
    features_url { stub_url(:account, "/users/#{id}/features") }

    initialize_with { attributes.as_json }
  end

  factory 'account:profile', class: Hash do
    user_id { generate(:user_id) }
    fields { [] }

    initialize_with { attributes.as_json }
  end

  factory 'account:authorization', class: Hash do
    id { generate(:uuid) }
    user_id { generate(:user_id) }
    sequence(:uid) {|n| String(n) }

    initialize_with { attributes.as_json }
  end

  factory 'account:email', class: Hash do
    id { generate(:uuid) }
    user_id { generate(:user_id) }
    sequence(:address) {|n| "eMail#{n}@openhpi.de" }
    self_url { stub_url(:account, "/users/#{user_id}/emails/#{id}") }
    suspension_url { stub_url(:account, "users/#{user_id}/emails/#{id}/suspension") }

    initialize_with { attributes.as_json }
  end

  xikolo_uuid_sequence(:email_id, service: 3100, resource: 5)

  factory :email, class: 'Account::Email' do
    association :user
    uuid { generate(:email_id) }
    sequence(:address) {|n| "email#{n}@example.com" }
    confirmed { false }
    confirmed_at { nil }
    primary { false }

    trait :confirmed do
      confirmed { true }
      confirmed_at { Time.zone.now }
    end

    trait :primary do
      primary { true }
    end
  end

  factory :treatment, class: 'Account::Treatment' do
    sequence(:name) {|n| "treatment#{n}" }

    after(:create) do |treatment|
      create(:group,
        name: "treatment.#{treatment.name}",
        description: "Users consenting to #{treatment.name}")
    end

    trait :external do
      consent_manager do
        {
          'type' => 'external',
          'consent_url' => 'https://example.com/consents',
        }
      end
    end
  end

  factory :consent, class: 'Account::Consent' do
    association :treatment
    association :user

    trait :consented do
      value { true }
    end

    trait :refused do
      value { false }
    end
  end
end
