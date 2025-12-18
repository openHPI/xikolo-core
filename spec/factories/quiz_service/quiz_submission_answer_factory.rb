# frozen_string_literal: true

FactoryBot.define do
  factory :'quiz_service/quiz_submission_answer' do
    association :quiz_submission_question, factory: :'quiz_service/quiz_submission_question'
    quiz_answer_id { '00000000-0000-4444-9999-000000000001' }

    factory :'quiz_service/quiz_submission_selectable_answer' do
      before(:create) do |submission_selectable_answer, _evaluator|
        submission_selectable_answer.type ||= 'QuizService::QuizSubmissionSelectableAnswer'
      end
    end

    factory :'quiz_service/quiz_submission_free_text_answer' do
      user_answer_text { '400' }

      before(:create) do |submission_free_test_answer, _evaluator|
        submission_free_test_answer.type ||= 'QuizService::QuizSubmissionFreeTextAnswer'
      end

      trait :long_text do
        user_answer_text { '404 long text Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.' }
      end
    end
  end
end
