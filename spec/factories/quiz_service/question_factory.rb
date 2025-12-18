# frozen_string_literal: true

FactoryBot.define do
  trait :base_question do
    association :quiz, factory: :'quiz_service/quiz'
    points { 10.0 }
    shuffle_answers { false }
    exclude_from_recap { false }
  end

  factory :'quiz_service/multiple_choice_question' do
    before(:create) do |question, _evaluator|
      question.type ||= 'QuizService::MultipleChoiceQuestion'
    end

    base_question
  end

  factory :'quiz_service/multiple_answer_question' do
    before(:create) do |question, _evaluator|
      question.type ||= 'QuizService::MultipleAnswerQuestion'
    end

    base_question
  end

  factory :'quiz_service/free_text_question' do
    before(:create) do |question, _evaluator|
      question.type ||= 'QuizService::FreeTextQuestion'
    end

    base_question
  end

  factory :'quiz_service/essay_question' do
    before(:create) do |question, _evaluator|
      question.type ||= 'QuizService::EssayQuestion'
    end

    base_question
  end
end
