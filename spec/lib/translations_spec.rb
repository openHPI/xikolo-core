# frozen_string_literal: true

require 'spec_helper'

describe Translations do
  subject(:translations) { described_class.new hash }

  let(:hash) do
    {de: 'Mikro-Lernen', en: 'Microlearning'}
  end

  describe '#to_s' do
    subject(:string) { translations.to_s }

    it 'uses the German translation when German locale is active' do
      I18n.with_locale(:de) do
        expect(string).to eq 'Mikro-Lernen'
      end
    end

    it 'uses the English translation when English locale is active' do
      I18n.with_locale(:en) do
        expect(string).to eq 'Microlearning'
      end
    end

    context 'when English is not available' do
      let(:hash) { {de: 'Mikro-Lernen'} }

      it 'falls back to the first available locale when requested locale is not available' do
        I18n.with_locale(:en) do
          expect(string).to eq 'Mikro-Lernen'
        end
      end
    end

    context 'with invalid (blank) input' do
      let(:hash) { nil }

      it 'returns an empty string' do
        expect(string).to eq ''
      end
    end

    context 'with a string instead of a hash' do
      let(:hash) { 'Micro-soft' }

      it 'returns that string' do
        expect(string).to eq 'Micro-soft'
      end
    end

    context 'with string keys in the input hash' do
      let(:hash) { super().stringify_keys }

      it 'works like before' do
        I18n.with_locale(:de) do
          expect(string).to eq 'Mikro-Lernen'
        end
      end
    end

    context 'with a specific locale preference' do
      let(:translations) { described_class.new(hash, locale_preference: %w[de en]) }

      it 'uses the defined locale preference even when the current locale is available' do
        I18n.with_locale(:en) do
          expect(string).to eq 'Mikro-Lernen'
        end
      end
    end
  end

  describe '#present?' do
    subject { translations.present? }

    context 'when translations are available' do
      it { is_expected.to be true }
    end

    context 'without any translations' do
      let(:hash) { {} }

      it { is_expected.to be false }
    end

    context 'with invalid (blank) input' do
      let(:hash) { nil }

      it { is_expected.to be false }
    end

    context 'with a string instead of a hash' do
      let(:hash) { 'Micro-soft' }

      it { is_expected.to be true }
    end
  end
end
