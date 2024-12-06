# frozen_string_literal: true

FactoryBot.define do
  factory :membership do
    association :collab_space
    sequence :user_id, '00000001-3100-4444-9999-000000000001'
    status { 'regular' }
  end
end
