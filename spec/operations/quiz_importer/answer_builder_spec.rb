# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::AnswerBuilder do
  describe '.build' do
    it 'builds a text answer for choice questions' do
      answer = described_class.build('4', 'TRUE', 'exact', 'MultipleChoice')

      expect(answer).to be_a(QuizImporter::Answer)
      expect(answer.type).to eq('TextAnswer')
      expect(answer.text).to eq('4')
      expect(answer.correct).to be(true)
      expect(answer.explanation).to eq('exact')
    end

    it 'builds a free text answer with forced correctness and empty explanation' do
      answer = described_class.build('any text', 'FALSE', 'ignored', 'FreeText')

      expect(answer.type).to eq('FreeTextAnswer')
      expect(answer.correct).to be(true)
      expect(answer.explanation).to eq('')
    end

    it 'raises for invalid answer' do
      expect { described_class.build('', 'YES', '', 'abced') }
        .to raise_error(QuizImporter::ProcessWorksheetError)
    end
  end
end
