# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QuizImporter::Answer do
  let(:valid_attrs) do
    {type: 'TextAnswer', text: '4', correct: true, explanation: 'basic arithmetic'}
  end

  it 'stores answer attributes' do
    answer = described_class.new(valid_attrs)

    expect(answer.type).to eq('TextAnswer')
    expect(answer.text).to eq('4')
    expect(answer.correct).to be(true)
    expect(answer.explanation).to eq('basic arithmetic')
  end

  it 'defaults explanation to empty string' do
    answer = described_class.new(valid_attrs.except(:explanation))

    expect(answer.explanation).to eq('')
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(described_class.new(valid_attrs)).to be_valid
    end

    it 'is invalid without text' do
      expect(described_class.new(valid_attrs.merge(text: ''))).not_to be_valid
    end

    it 'is invalid with an unknown type' do
      expect(described_class.new(valid_attrs.merge(type: 'BooleanAnswer'))).not_to be_valid
    end

    it 'is valid with all known types' do
      %w[TextAnswer FreeTextAnswer].each do |type|
        expect(described_class.new(valid_attrs.merge(type: type))).to be_valid
      end
    end

    it 'is invalid when correct is nil' do
      expect(described_class.new(valid_attrs.merge(correct: nil))).not_to be_valid
    end
  end
end
