# frozen_string_literal: true

require 'spec_helper'

describe Question, type: :model do
  subject(:question) { create(:multiple_choice_question) }

  it { is_expected.to accept_values_for(:type, 'Xikolo::Quiz::MultipleChoiceQuestion', 'Xikolo::Quiz::MultipleAnswerQuestion', 'Xikolo::Quiz::FreeTextQuestion') }
  it { is_expected.to accept_values_for(:shuffle_answers, true, false) }
  it { is_expected.to accept_values_for(:position, 1) }
  it { is_expected.to accept_values_for(:points, 1.3) }
  it { is_expected.to accept_values_for(:exclude_from_recap, true, false) }

  describe 'explanation' do
    let(:question) { build(:multiple_choice_question, explanation: '') }

    it 'stores empty strings as null value' do
      question.save!
      expect(question.reload.explanation).to be_nil
    end
  end

  context '(event publication)' do
    let(:question) { build(:multiple_choice_question) }
    let(:expected_question) do
      {
        quiz_id: subject.quiz_id,
      }.as_json
    end

    describe 'create question' do
      it 'publishes an event for a newly created question' do
        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq expected_question
          expect(opts).to eq to: 'xikolo.quiz.question.create'
        end

        question.save
      end
    end

    describe 'update question' do
      it 'publishes an event for an updated question' do
        question.save

        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq expected_question
          expect(opts).to eq to: 'xikolo.quiz.question.update'
        end

        question.save
      end
    end

    describe 'destroy question' do
      it 'publishes an event for a destroyed question' do
        question.save

        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq expected_question
          expect(opts).to eq to: 'xikolo.quiz.question.destroy'
        end

        question.destroy
      end
    end
  end
end
