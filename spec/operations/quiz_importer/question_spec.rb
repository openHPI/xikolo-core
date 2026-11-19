# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::Question do
  let(:valid_attrs) do
    {text: 'Q1', type: 'MultipleChoice', points: 2}
  end

  it 'initializes with defaults' do
    question = described_class.new(valid_attrs)

    expect(question.text).to eq('Q1')
    expect(question.type).to eq('MultipleChoice')
    expect(question.points).to eq(2)
    expect(question.explanation).to eq('')
    expect(question.exclude_from_recap).to be(false)
    expect(question.shuffle_answers).to be(true)
    expect(question.answers).to eq([])
  end

  it 'adds answers' do
    question = described_class.new(valid_attrs)
    answer = instance_double(QuizImporter::Answer)

    question.add_answer(answer)

    expect(question.answers).to eq([answer])
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(described_class.new(valid_attrs)).to be_valid
    end

    it 'is invalid without text' do
      expect(described_class.new(valid_attrs.merge(text: ''))).not_to be_valid
    end

    it 'is invalid with an unknown type' do
      expect(described_class.new(valid_attrs.merge(type: 'TrueFalse'))).not_to be_valid
    end

    it 'is valid with all known types' do
      %w[MultipleChoice MultipleAnswer FreeText].each do |type|
        expect(described_class.new(valid_attrs.merge(type: type))).to be_valid
      end
    end

    it 'is invalid with negative points' do
      expect(described_class.new(valid_attrs.merge(points: -1))).not_to be_valid
    end
  end
end
