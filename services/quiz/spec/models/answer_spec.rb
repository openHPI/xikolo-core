# frozen_string_literal: true

require 'spec_helper'

describe Answer, type: :model do
  subject(:answer) { build(:text_answer, question:) }

  let!(:question) { create(:multiple_answer_question) }

  it 'has a valid factory' do
    expect(answer).to be_valid
  end

  context '(event publication)' do
    let(:expected_answer) do
      {
        question_id: question.id,
      }.as_json
    end

    describe 'create answer' do
      it 'publishes an event for a newly created answer' do
        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq expected_answer
          expect(opts).to eq to: 'xikolo.quiz.answer.create'
        end

        answer.save
      end
    end

    describe 'update answer' do
      it 'publishes an event for an updated answer' do
        answer.save

        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq expected_answer
          expect(opts).to eq to: 'xikolo.quiz.answer.update'
        end

        answer.save
      end
    end

    describe 'destroy answer' do
      it 'publishes an event for a destroyed answer' do
        answer.save

        expect(Msgr).to receive(:publish) do |event, opts|
          expect(event).to eq expected_answer
          expect(opts).to eq to: 'xikolo.quiz.answer.destroy'
        end

        answer.destroy
      end
    end
  end
end
