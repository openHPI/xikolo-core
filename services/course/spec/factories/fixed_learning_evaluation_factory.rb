# frozen_string_literal: true

FactoryBot.define do
  factory :fixed_learning_evaluation do
    user_id
    course
    sequence(:maximal_dpoints) {|n| (n * 10) + 3 }
    user_dpoints { (maximal_dpoints * 0.73).to_i }
    visits_percentage { 0.41209 }
  end
end
