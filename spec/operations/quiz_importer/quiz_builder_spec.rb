# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::QuizBuilder do
  describe '.build' do
    it 'builds a quiz from a valid row' do
      row = ['Quiz 1', '3.2', 'bonus', 'Read carefully']

      quiz = described_class.build(row)

      expect(quiz).to be_a(QuizImporter::Quiz)
      expect(quiz.name).to eq('Quiz 1')
      expect(quiz.section).to eq(3)
      expect(quiz.subsection).to eq(2)
      expect(quiz.type).to eq('bonus')
      expect(quiz.instructions).to eq('Read carefully')
      expect(quiz.attempts).to eq(1)
      expect(quiz.time).to eq(3600)
      expect(quiz.graded).to be(true)
      expect(quiz.bonus).to be(true)
      expect(quiz.survey).to be(false)
    end

    it 'raises for unknown quiz type' do
      row = ['Quiz 1', '1', 'unknown-type', '']

      expect { described_class.build(row) }
        .to raise_error(QuizImporter::ProcessWorksheetError, /Type is not included in the list/)
    end

    it 'raises for invalid section' do
      row = ['Quiz 1', 'x.y', 'selftest', '']

      expect { described_class.build(row) }
        .to raise_error(QuizImporter::ProcessWorksheetError, /Wrong format for quiz section/)
    end
  end
end
