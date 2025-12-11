# frozen_string_literal: true

require 'spec_helper'

Rails.application.load_tasks

RSpec.describe 'migrate_polymorfic_data:down' do
  before do
    free_text_question = create(:'quiz_service/free_text_question')
    create(:'quiz_service/free_text_answer', question: free_text_question)
    create(:'quiz_service/text_answer', question: free_text_question)
    create(:'quiz_service/essay_question')
    create(:'quiz_service/multiple_answer_question')
    create(:'quiz_service/multiple_choice_question')
    create(:'quiz_service/quiz_submission_free_text_answer')
    create(:'quiz_service/quiz_submission_selectable_answer')
  end

  describe ':up', skip: 'cases random test errors, locally tested' do
    it 'adds prefixes for QuizService' do
      Rake::Task['migrate_polymorfic_data:down'].reenable
      Rake::Task['migrate_polymorfic_data:down'].invoke

      expect do
        Rake::Task['migrate_polymorfic_data:up'].reenable
        Rake::Task['migrate_polymorfic_data:up'].invoke
      end.to change(QuizService::FreeTextAnswer, :count).to(1)
        .and change(QuizService::TextAnswer, :count).to(1)
        .and change(QuizService::FreeTextQuestion, :count).to(1)
        .and change(QuizService::EssayQuestion, :count).to(1)
        .and change(QuizService::MultipleAnswerQuestion, :count).to(1)
        .and change(QuizService::MultipleChoiceQuestion, :count).to(1)
        .and change(QuizService::QuizSubmissionFreeTextAnswer, :count).to(1)
        .and change(QuizService::QuizSubmissionSelectableAnswer, :count).to(1)
    end
  end

  describe ':down', skip: 'cases random test errors, locally tested' do
    it 'removes all prefixes' do
      expect do
        Rake::Task['migrate_polymorfic_data:down'].reenable
        Rake::Task['migrate_polymorfic_data:down'].invoke
      end.to change(FreeTextAnswer, :count).to(1)
        .and change(TextAnswer, :count).to(1)
        .and change(FreeTextQuestion, :count).to(1)
        .and change(EssayQuestion, :count).to(1)
        .and change(MultipleAnswerQuestion, :count).to(1)
        .and change(MultipleChoiceQuestion, :count).to(1)
        .and change(QuizSubmissionFreeTextAnswer, :count).to(1)
        .and change(QuizSubmissionSelectableAnswer, :count).to(1)
    end
  end
end
