# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::Scanner do
  let(:header) { %w[Quiz Title Type Q1 Q2 Q3 Q4 Q5 A1 A2 A3] }
  let(:quiz_row) { ['Quiz 1', 'Sample Quiz', 'multiple_choice', '', '', '', '', '', '', '', ''] }
  let(:question_row) { [nil, nil, nil, nil, 'What is 2+2?', '', '', '', '4', 'true', ''] }
  let(:rows) { [header, quiz_row, question_row] }
  let(:scanner) { described_class.new(rows) }

  it 'returns quizzes with questions and answers' do
    quiz = instance_double(QuizImporter::Quiz, type: 'multiple_choice')
    question = instance_double(QuizImporter::Question, type: 'multiple_choice')
    answer = instance_double(QuizImporter::Answer)
    allow(QuizImporter::QuizBuilder).to receive(:build).and_return(quiz)
    allow(QuizImporter::QuestionBuilder).to receive(:build).and_return(question)
    allow(QuizImporter::AnswerBuilder).to receive(:build).and_return(answer)
    allow(quiz).to receive(:add_question).with(question)
    allow(question).to receive(:add_answer).with(answer)
    result = scanner.scan
    expect(result).to eq([quiz])
  end

  it 'raises if question found before quiz' do
    bad_rows = [header, question_row]
    s = described_class.new(bad_rows)
    expect { s.scan }.to raise_error(QuizImporter::ProcessWorksheetError, /Question found before any quiz/)
  end
end
