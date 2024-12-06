# frozen_string_literal: true

require 'spec_helper'

describe QuizSubmissionQuestion, type: :model do
  subject { quiz_submission_question }

  let(:params) { {} }
  let(:quiz_submission_question) { create(:quiz_submission_question, params) }

  context 'similar quiz_submission with same quiz_' do
    subject { similar_quiz_submission_question }

    before { quiz_submission_question }

    let(:submission) { create(:quiz_submission, :submitted) }
    let(:second_submission) { create(:quiz_submission, :submitted) }
    let(:params) { {quiz_question_id: '00000000-0000-4444-9999-000000000001', quiz_submission_id: submission.id} }
    let(:second_params) { params }
    let(:similar_quiz_submission_question) { build(:quiz_submission_question, second_params) }

    describe 'rails validation' do
      context 'only with same quiz_question_id' do
        let(:second_params) { {quiz_question_id: params[:quiz_question_id], quiz_submission_id: second_submission.id} }

        it { is_expected.to be_valid }
      end

      context 'only with same quiz_submission_id' do
        let(:second_params) { {quiz_question_id: '00000000-0000-4444-9999-AAAAAAAAAAAA', quiz_submission_id: params[:quiz_submission_id]} }

        it { is_expected.to be_valid }
      end

      context 'with both same quiz_question_id and quiz_submission_id' do
        it { is_expected.not_to be_valid }
        it { is_expected.to have(1).error_on(:quiz_question_id) }
      end
    end

    describe 'database uniqueness' do
      it 'raises database error' do
        expect { similar_quiz_submission_question.save! validate: false }.to raise_error ActiveRecord::RecordNotUnique
      end
    end
  end

  context 'question points are nil' do
    let!(:quiz) { create(:quiz) }
    let(:quiz_question_id) { '00000000-0000-4444-9999-430000000345' }
    let(:quiz_answer_id) { '00000000-0000-4444-9999-000000000023' }
    let(:question_points) { 10.0 }

    let(:submission_question) { create(:quiz_submission_question, points: nil, quiz_question_id:) }
    let(:submission_selectable_answer) { create(:quiz_submission_selectable_answer, quiz_submission_question: submission_question, quiz_answer_id:) }
    let(:submission_free_text_answer) { create(:quiz_submission_free_text_answer, quiz_submission_question: submission_question, quiz_answer_id:) }
    let(:submission_essay_answer) { create(:quiz_submission_free_text_answer, :long_text, quiz_submission_question: submission_question, quiz_answer_id:) }

    context 'with a MultipleChoiceQuestion' do
      subject { submission_question }

      before do
        create(:multiple_choice_question,
          id: quiz_question_id,
          quiz:,
          points: question_points,
          shuffle_answers: true,
          position: 3)

        create(:text_answer,
          id: quiz_answer_id,
          question_id: quiz_question_id,
          comment: 'Kekse sind lecker.',
          correct: true)

        submission_question
        submission_selectable_answer
      end

      its(:points) { is_expected.to equal question_points }
    end

    context 'with a FreeTextQuestion' do
      subject { submission_question }

      before do
        create(:free_text_question,
          id: quiz_question_id,
          quiz:,
          points: question_points,
          shuffle_answers: true,
          position: 3)

        create(:text_answer,
          id: quiz_answer_id,
          question_id: quiz_question_id,
          comment: 'Kekse sind lecker.',
          correct: true,
          text: '400')

        submission_question
        submission_free_text_answer
      end

      its(:points) { is_expected.to equal question_points }
    end

    context 'with an EssayQuestion' do
      subject { submission_question }

      before do
        create(:essay_question,
          id: quiz_question_id,
          quiz:,
          points: question_points,
          shuffle_answers: true,
          position: 3)

        submission_question
        submission_essay_answer
      end

      its(:points) { is_expected.to equal question_points }
    end

    context 'with a MultipleAnswerQuestion' do
      context 'with no selected answer' do
        subject { submission_question }

        before do
          create(:multiple_answer_question,
            id: quiz_question_id,
            quiz:,
            points: question_points,
            shuffle_answers: true,
            position: 3)

          submission_question
          submission_selectable_answer
        end

        its(:points) { is_expected.to equal 0.0 }
      end

      context 'with one selected answer' do
        subject { submission_question }

        before do
          create(:multiple_answer_question,
            id: quiz_question_id,
            quiz:,
            points: question_points,
            shuffle_answers: true,
            position: 3)

          create(:text_answer,
            id: quiz_answer_id,
            question_id: quiz_question_id,
            comment: 'Kekse sind lecker.',
            correct: true)
          submission_question
          submission_selectable_answer
        end

        its(:points) { is_expected.to equal question_points }
      end

      context 'with two selected answers' do
        subject { submission_question }

        let(:second_quiz_answer_id) { '00000000-0000-4444-9999-000000000024' }
        let(:second_submission_selectable_answer) { create(:quiz_submission_selectable_answer, quiz_submission_question: submission_question, quiz_answer_id: second_quiz_answer_id) }

        before do
          create(:multiple_answer_question,
            id: quiz_question_id,
            quiz:,
            points: question_points,
            shuffle_answers: true,
            position: 3)

          create(:text_answer,
            id: quiz_answer_id,
            question_id: quiz_question_id,
            comment: 'Kekse sind lecker.',
            correct: true)
          create(:text_answer,
            id: second_quiz_answer_id,
            question_id: quiz_question_id,
            comment: 'Kekse sind toll.',
            correct: true)

          submission_question
          submission_selectable_answer
          second_submission_selectable_answer
        end

        its(:points) { is_expected.to equal question_points }
      end
    end
  end
end
