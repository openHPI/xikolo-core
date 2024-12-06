# frozen_string_literal: true

FactoryBot.define do
  factory :session do
    user
  end

  factory :user do
    transient do
      completed_profile { true }
    end

    password { 'secret123' }
    language { 'en' }

    sequence(:full_name) {|n| "John Smith, the #{n.ordinalize}" }
    display_name { 'John Smith' }

    after(:create) do |user, evaluator|
      if evaluator.completed_profile
        user.features.create(
          name: 'account.profile.mandatory_completed',
          value: 'true',
          context: Context.root
        )
      end

      create(:email, user:, primary: true, confirmed: true)
      user.primary_email.reload
    end

    trait :with_affiliation do
      transient do
        affiliation { nil }
      end

      after(:create) do |user, evaluator|
        field = CustomTextField.find_or_create_by(context: 'user', name: 'affiliation')

        if evaluator.affiliation
          create(:custom_field_value, custom_field: field, context_id: user.id, context_type: 'user', values: [evaluator.affiliation])
        end
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

    trait :unconfirmed do
      after(:create) do |user|
        user.update! confirmed: false
        user.emails.update_all confirmed: false, confirmed_at: nil # rubocop:disable Rails/SkipsModelValidations
      end
    end

    trait :admin do
      after(:create) do |user|
        user.memberships.create! group: Group.administrators
      end
    end
  end

  factory :group do
    sequence(:name) {|n| "test.group#{n}" }
  end

  factory :membership do
    group
    user
  end

  factory :feature do
    sequence(:name) {|n| "flipper.nr#{n}" }
    value { 'true' }
    context_id { Context.root_id }

    association :owner, factory: :group
  end

  factory :email do
    sequence(:uuid) {|n| "00000001-3100-4444-9999-10000000#{1000 + n}" }
    confirmed { true }
    confirmed_at { nil }
    sequence(:address) {|n| "eMail#{n}@example.de" }
    association :user

    trait :confirmed do
      confirmed { true }
      confirmed_at { Time.zone.now }
    end
  end

  factory :token do
    user

    trait :with_client_application do
      user { nil }
      association :owner, factory: :client_application
    end

    trait :with_user_polymorphic do
      user { nil }
      association :owner, factory: :user
    end
  end

  factory :client_application do
    sequence(:name) {|n| "Client App ##{n}" }
  end

  factory :authorization do
    user
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

  factory :custom_field do
    name { 'fn' }
    context { 'user' }

    required { false }

    initialize_with { raise 'Use STI subclass' }
  end

  factory :custom_text_field, class: 'CustomField', parent: :custom_field do
    values { [] }
    default_values { [] }

    initialize_with { CustomTextField.new }
  end

  factory :custom_select_field, class: 'CustomField', parent: :custom_field do
    values { %w[none A B C] }
    default_values { %w[none] }

    initialize_with { CustomSelectField.new }
  end

  factory :custom_multi_select_field, class: 'CustomField', parent: :custom_field do
    values { %w[A B C] }
    default_values { %w[] }

    initialize_with { CustomMultiSelectField.new }
  end

  factory :custom_field_value do
    association :custom_field, factory: :custom_text_field
  end

  factory :password_reset do
    user
  end

  factory :context do
    parent_id { Context.root_id }
  end

  sequence :permission do |n|
    "xikolo.test.perm_#{n}"
  end

  factory :role do
    permissions { Array.new(5) { generate(:permission) } }

    trait :with_name do
      sequence(:name) {|n| "account.#{n}" }
    end
  end

  factory :grant do
    association :role
    association :principal, factory: :user

    context_id { Context.root_id }
  end

  factory :policy do
    url_data = {en: 'http://www.example.com/about/legal/privacy.html'}
    version { 1 }
    url { url_data }
  end

  factory :treatment do
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

  factory :consent do
    association :treatment
    association :user
    value { true }
    created_at { 5.years.ago }
  end
end
