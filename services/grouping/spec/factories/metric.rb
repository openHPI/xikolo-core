# frozen_string_literal: true

FactoryBot.define do
  factory :metric, class: 'Metrics::Metric' do
    name { 'Metric' }
    wait_interval { 0 }
  end

  factory :enrollments_metric, class: 'Metrics::EnrollmentsMetric' do
    name { 'Enrollments' }
    wait_interval { 0 }
    distribution { :normal }

    trait :waiting do
      wait { true }
      wait_interval { 2.hours }
    end
  end
end
