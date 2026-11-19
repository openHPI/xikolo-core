# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::QuestionBuilder do
  describe '.build' do
    it 'builds a question from a valid row' do
      row = ['What is 2+2?', 'SingleSelect', '3', 'Because math', 'TRUE']

      question = described_class.build(row, 'selftest')

      expect(question).to be_a(QuizImporter::Question)
      expect(question.text).to eq('What is 2+2?')
      expect(question.type).to eq('MultipleChoice')
      expect(question.points).to eq(3)
      expect(question.explanation).to eq('Because math')
      expect(question.exclude_from_recap).to be(true)
      expect(question.shuffle_answers).to be(true)
    end

    it 'disables answer shuffle for survey quiz type' do
      row = ['Feedback?', 'FreeText', '0', '', 'FALSE']

      question = described_class.build(row, 'survey')

      expect(question.shuffle_answers).to be(false)
    end

    it 'raises for invalid question type' do
      row = ['Q1', 'BadType', '1', '', 'FALSE']

      expect { described_class.build(row, 'selftest') }
        .to raise_error(QuizImporter::ProcessWorksheetError, /Type is not included/)
    end
  end
end
