# frozen_string_literal: true

FactoryBot.define do
  factory :'quiz_service/answer' do
    association :question, factory: :'quiz_service/multiple_answer_question'
    comment { 'This is the correct answer, well done.' }
    position { 10 }
    correct { true }

    factory :'quiz_service/text_answer', parent: :'quiz_service/answer' do
      before(:create) do |text_answer, _evaluator|
        text_answer.type ||= 'QuizService::TextAnswer'
      end
    end

    factory :'quiz_service/free_text_answer', parent: :'quiz_service/answer' do
      before(:create) do |free_test_answer, _evaluator|
        free_test_answer.type ||= 'QuizService::FreeTextAnswer'
      end

      association :question, factory: :'quiz_service/free_text_question'
    end
  end
end
