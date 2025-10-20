# frozen_string_literal: true

FactoryBot.define do
  factory :'course_service/fixed_learning_evaluation', class: 'FixedLearningEvaluation' do
    user_id
    association :course, factory: :'course_service/course'
    sequence(:maximal_dpoints) {|n| (n * 10) + 3 }
    user_dpoints { (maximal_dpoints * 0.73).to_i }
    visits_percentage { 0.41209 }
  end
end
