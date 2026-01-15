# frozen_string_literal: true

FactoryBot.define do
  factory :'account_service/session' do
    association :user, factory: :'account_service/user'
  end

  factory :'account_service/user' do
    transient do
      completed_profile { true }
    end

    password { 'secret123' }
    language { 'en' }
    status { 'other' }

    sequence(:full_name) {|n| "John Smith, the #{n.ordinalize}" }
    display_name { 'John Smith' }

    after(:create) do |user, evaluator|
      if evaluator.completed_profile
        user.features.create(
          name: 'account.profile.mandatory_completed',
          value: 'true',
          context: AccountService::Context.root
        )
      end

      create(:'account_service/email', user:, primary: true, confirmed: true)
      user.primary_email.reload
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

    trait :unconfirmed do
      after(:create) do |user|
        user.update! confirmed: false
        user.emails.update_all confirmed: false, confirmed_at: nil # rubocop:disable Rails/SkipsModelValidations
      end
    end

    trait :admin do
      after(:create) do |user|
        user.memberships.create! group: AccountService::Group.administrators
      end
    end
  end

  factory :'account_service/group' do
    sequence(:name) {|n| "test.group#{n}" }
  end

  factory :'account_service/membership' do
    association :group, factory: :'account_service/group'
    association :user, factory: :'account_service/user'
  end

  factory :'account_service/feature' do
    sequence(:name) {|n| "flipper.nr#{n}" }
    value { 'true' }
    context_id { AccountService::Context.root_id }

    association :owner, factory: :'account_service/group'
  end

  factory :'account_service/email' do
    sequence(:uuid) {|n| "00000001-3100-4444-9999-10000000#{1000 + n}" }
    confirmed { true }
    confirmed_at { nil }
    sequence(:address) {|n| "eMail#{n}@example.de" }
    association :user, factory: :'account_service/user'

    trait :confirmed do
      confirmed { true }
      confirmed_at { Time.zone.now }
    end
  end

  factory :'account_service/token' do
    association :user, factory: :'account_service/user'

    trait :with_client_application do
      user { nil }
      association :owner, factory: :'account_service/client_application'
    end

    trait :with_user_polymorphic do
      user { nil }
      association :owner, factory: :'account_service/user'
    end
  end

  factory :'account_service/client_application' do
    sequence(:name) {|n| "Client App ##{n}" }
  end

  factory :'account_service/authorization' do
    association :user, factory: :'account_service/user'
    provider { 'test' }
    sequence(:uid) {|n| String(n) }
    expires_at { 4.days.from_now }
    info do
      {
        nickname: 'jbloggs',
        email: 'joe@bloggs.com',
        name: 'Joe Bloggs',
        first_name: 'Joe',
        last_name: 'Bloggs',
        image: 'http://graph.facebook.com/1234567/picture?type=square',
        urls: {Facebook: 'http://www.facebook.com/jbloggs'},
        location: 'Palo Alto, California',
        verified: true,
        raw: {
          id: '1234567',
          name: 'Joe Bloggs',
          first_name: 'Joe',
          last_name: 'Bloggs',
          link: 'http://www.facebook.com/jbloggs',
          username: 'jbloggs',
          location: {id: '123456789', name: 'Palo Alto, California'},
          gender: 'male',
          email: 'joe@bloggs.com',
          timezone: -8,
          locale: 'en_US',
          verified: true,
          updated_time: '2011-11-11T06:21:03+0000',
        },
      }
    end
  end

  factory :'account_service/password_reset' do
    association :user, factory: :'account_service/user'
  end

  factory :'account_service/context' do
    parent_id { AccountService::Context.root_id }
  end

  sequence :permission do |n|
    "xikolo.test.perm_#{n}"
  end

  factory :'account_service/role' do
    permissions { Array.new(5) { generate(:permission) } }

    trait :with_name do
      sequence(:name) {|n| "account.#{n}" }
    end
  end

  factory :'account_service/grant' do
    association :role, factory: :'account_service/role'
    association :principal, factory: :'account_service/user'

    context_id { AccountService::Context.root_id }
  end

  factory :'account_service/policy' do
    url_data = {en: 'http://www.example.com/about/legal/privacy.html'}
    version { 1 }
    url { url_data }
  end

  factory :'account_service/treatment' do
    sequence(:name) {|n| "treatment#{n}" }

    trait :external do
      consent_manager do
        {
          'type' => 'external',
          'consent_url' => 'https://example.com/consents',
        }
      end
    end
  end

  factory :'account_service/consent' do
    association :treatment, factory: :'account_service/treatment'
    association :user, factory: :'account_service/user'
    value { true }
    created_at { 5.years.ago }
  end
end
