# frozen_string_literal: true

FactoryBot.define do
  factory :filter do
    field_name { 'gender' }
    operator { '==' }
    field_value { 'female' }

    factory :enrollments_filter do
      field_name { 'enrollments' }
      operator { '<=' }
      field_value { '1' }
    end
  end
end
