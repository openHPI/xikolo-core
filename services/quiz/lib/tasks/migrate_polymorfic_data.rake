# frozen_string_literal: true

namespace :migrate_polymorfic_data do
  desc 'Update plymorfic and STI data to include AccountService namespace'
  task up: :environment do
    # rubocop:disable Rails/SkipsModelValidations, Layout/LineLength
    FreeTextAnswer.where(type: 'FreeTextAnswer').in_batches.update_all(type: 'QuizService::FreeTextAnswer')
    TextAnswer.where(type: 'TextAnswer').in_batches.update_all(type: 'QuizService::TextAnswer')
    FreeTextQuestion.where(type: 'FreeTextQuestion').in_batches.update_all(type: 'QuizService::FreeTextQuestion')
    EssayQuestion.where(type: 'EssayQuestion').in_batches.update_all(type: 'QuizService::EssayQuestion')
    MultipleAnswerQuestion.where(type: 'MultipleAnswerQuestion').in_batches.update_all(type: 'QuizService::MultipleAnswerQuestion')
    MultipleChoiceQuestion.where(type: 'MultipleChoiceQuestion').in_batches.update_all(type: 'QuizService::MultipleChoiceQuestion')
    QuizSubmissionFreeTextAnswer.where(type: 'QuizSubmissionFreeTextAnswer').in_batches.update_all(type: 'QuizService::QuizSubmissionFreeTextAnswer')
    QuizSubmissionSelectableAnswer.where(type: 'QuizSubmissionSelectableAnswer').in_batches.update_all(type: 'QuizService::QuizSubmissionSelectableAnswer')
    # rubocop:enable Rails/SkipsModelValidations, Layout/LineLength
  end

  task down: :environment do
    # rubocop:disable Rails/SkipsModelValidations, Layout/LineLength
    QuizService::FreeTextAnswer.where(type: 'QuizService::FreeTextAnswer').in_batches.update_all(type: 'FreeTextAnswer')
    QuizService::TextAnswer.where(type: 'QuizService::TextAnswer').in_batches.update_all(type: 'TextAnswer')
    QuizService::FreeTextQuestion.where(type: 'QuizService::FreeTextQuestion').in_batches.update_all(type: 'FreeTextQuestion')
    QuizService::EssayQuestion.where(type: 'QuizService::EssayQuestion').in_batches.update_all(type: 'EssayQuestion')
    QuizService::MultipleAnswerQuestion.where(type: 'QuizService::MultipleAnswerQuestion').in_batches.update_all(type: 'MultipleAnswerQuestion')
    QuizService::MultipleChoiceQuestion.where(type: 'QuizService::MultipleChoiceQuestion').in_batches.update_all(type: 'MultipleChoiceQuestion')
    QuizService::QuizSubmissionFreeTextAnswer.where(type: 'QuizService::QuizSubmissionFreeTextAnswer').in_batches.update_all(type: 'QuizSubmissionFreeTextAnswer')
    QuizService::QuizSubmissionSelectableAnswer.where(type: 'QuizService::QuizSubmissionSelectableAnswer').in_batches.update_all(type: 'QuizSubmissionSelectableAnswer')
    # rubocop:enable Rails/SkipsModelValidations, Layout/LineLength
  end
end
