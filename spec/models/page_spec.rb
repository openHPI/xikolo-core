# frozen_string_literal: true

require 'spec_helper'

describe Page, type: :model do
  it { is_expected.to accept_values_for(:locale, 'de', 'kaa', 'pt-BR') }
  it { is_expected.not_to accept_values_for(:locale, 'deee', 'ptBR') }

  describe '(associations)' do
    let(:page) { create(:page, :english, name: 'foo') }

    before do
      create(:page, :german, name: 'foo')
      create(:page, :german, name: 'bar')
    end

    describe '#other_translations' do
      it 'returns other translations for the same page' do
        expect(page.other_translations).to contain_exactly(an_object_having_attributes(name: 'foo', locale: 'de'))
      end
    end

    describe '#translations' do
      it 'returns all translations including itself for the same page' do
        expect(page.translations).to contain_exactly(an_object_having_attributes(name: 'foo', locale: 'de'), page)
      end
    end
  end

  describe '(scopes)' do
    describe '.preferred_locales' do
      before do
        create(:page, :english, name: 'foo', created_at: 1.day.ago)
        create(:page, :german, name: 'foo', created_at: 2.days.ago)
        create(:page, locale: 'fr', name: 'foo', created_at: 3.days.ago)
        create_list(:page, 2, :english, created_at: 4.days.ago)
      end

      it 'returns matching translations by the given order of preference' do
        expect(described_class.preferred_locales('en', 'de')).to match [
          have_attributes(locale: 'en'),
          have_attributes(locale: 'en'),
          have_attributes(locale: 'en'),
          have_attributes(locale: 'de'),
          have_attributes(locale: 'fr'),
        ]

        expect(described_class.preferred_locales('de', 'en')).to match [
          have_attributes(locale: 'de'),
          have_attributes(locale: 'en'),
          have_attributes(locale: 'en'),
          have_attributes(locale: 'en'),
          have_attributes(locale: 'fr'),
        ]
      end

      it 'orders non-matching translations by creation date, oldest first' do
        expect(described_class.preferred_locales('cn', 'uk')).to match [
          have_attributes(locale: 'en'),
          have_attributes(locale: 'en'),
          have_attributes(locale: 'fr'),
          have_attributes(locale: 'de'),
          have_attributes(locale: 'en'),
        ]
      end
    end
  end
end
