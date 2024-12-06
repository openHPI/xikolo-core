# frozen_string_literal: true

FactoryBot.define do
  factory :voucher, class: 'Voucher::Voucher' do
    country { 'DE' }

    trait :proctoring do
      product_type { 'proctoring_smowl' }
    end

    trait :reactivation do
      product_type { 'course_reactivation' }
    end

    trait :claimed do
      claimed_at { 1.day.ago }
      claimant_id { generate(:user_id) }
      course_id { generate(:course_id) }
      claimant_ip { '::' }
      claimant_country { 'AAA' }
    end
  end
end
