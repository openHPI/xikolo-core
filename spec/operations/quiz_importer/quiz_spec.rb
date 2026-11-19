# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::Quiz do
  let(:valid_attrs) do
    {
      name: 'Quiz 1',
      section: 2,
      type: 'selftest',
      attempts: 0,
      time: 0,
      graded: false,
      bonus: false,
      survey: false,
    }
  end

  it 'initializes with required fields and defaults' do
    quiz = described_class.new(valid_attrs)

    expect(quiz.name).to eq('Quiz 1')
    expect(quiz.section).to eq(2)
    expect(quiz.subsection).to be_nil
    expect(quiz.instructions).to eq('')
    expect(quiz.questions).to eq([])
  end

  it 'adds questions' do
    quiz = described_class.new(valid_attrs)
    q = instance_double(QuizImporter::Question)
    quiz.add_question(q)

    expect(quiz.questions).to eq([q])
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(described_class.new(valid_attrs)).to be_valid
    end

    it 'is invalid without a name' do
      expect(described_class.new(valid_attrs.merge(name: ''))).not_to be_valid
    end

    it 'is invalid with an unknown type' do
      expect(described_class.new(valid_attrs.merge(type: 'unknown'))).not_to be_valid
    end

    it 'is invalid with a negative section' do
      expect(described_class.new(valid_attrs.merge(section: -1))).not_to be_valid
    end

    it 'is invalid with a negative subsection' do
      expect(described_class.new(valid_attrs.merge(subsection: -1))).not_to be_valid
    end

    it 'is valid with a nil subsection' do
      expect(described_class.new(valid_attrs.merge(subsection: nil))).to be_valid
    end

    it 'is invalid with a negative attempts value' do
      expect(described_class.new(valid_attrs.merge(attempts: -1))).not_to be_valid
    end

    it 'is invalid with a negative time value' do
      expect(described_class.new(valid_attrs.merge(time: -1))).not_to be_valid
    end
  end
end
