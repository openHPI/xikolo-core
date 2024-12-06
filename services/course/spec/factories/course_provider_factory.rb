# frozen_string_literal: true

FactoryBot.define do
  factory :course_provider do
    sequence(:name) {|n| "provider-#{n}" }
    sequence(:provider_type) {|n| "Provider#{n}" }
    config { {key: 'value'} }
    enabled { true }

    trait :successfactors do
      name { 'Company LMS' }
      provider_type { 'Successfactors' }
      config do
        {
          client_id: 'company',
          client_secret: 'abc123',
          base_url: 'https://companylearning.example.com',
          user_id: 'brand_API',
          company_id: 'brand',
          provider_id: 'brand1',
          launch_url_template: 'https://{host}/go/launch/{course}/example',
        }.stringify_keys
      end
      enabled { true }
    end
  end
end
