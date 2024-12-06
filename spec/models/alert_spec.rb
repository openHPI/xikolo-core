# frozen_string_literal: true

require 'spec_helper'

describe Alert, type: :model do
  subject(:alert) { described_class.new attrs }

  let(:attrs) { {} }

  describe '(validations)' do
    context 'with the default translation' do
      let(:attrs) do
        {
          translations: {
            en: {title: 'Hey users!', text: 'Watch out'},
          },
        }
      end

      it { is_expected.to be_valid }

      it 'stores the translation' do
        alert.save!
        expect(Alert.first.translations.keys).to eq %w[en]
      end

      context 'and additional translations' do
        let(:attrs) do
          {
            translations: {
              en: {title: 'Hey users!', text: 'Watch out'},
              de: {title: 'Hi Leute!', text: 'Passt mal auf'},
            },
          }
        end

        it { is_expected.to be_valid }

        it 'stores both translations' do
          alert.save!
          expect(Alert.first.translations.keys).to match_array %w[en de]
        end
      end
    end

    context 'with non-default translations only' do
      let(:attrs) do
        {
          translations: {
            de: {title: 'Hi Leute!', text: 'Passt mal auf'},
          },
        }
      end

      it 'responds with missing translations error' do
        expect { alert.save! }.to raise_error(ActiveRecord::RecordInvalid) do |error|
          expect(error.record.errors.messages).to eq translations: %w[default_translation_missing]
        end
      end
    end
  end

  describe '.by_publication_date' do
    subject(:ordered) { described_class.by_publication_date }

    let!(:past_alert) { create(:alert, :past) }
    let!(:current_alert) { create(:alert, :published) }
    let!(:future_alert) { create(:alert, :future) }
    let!(:draft_alert) { create(:alert) }

    it 'orders them by publication date, preceded by drafts' do
      expect(ordered.pluck(:id)).to match [
        draft_alert.id,
        future_alert.id,
        current_alert.id,
        past_alert.id,
      ]
    end
  end

  describe '.published' do
    subject(:published) { described_class.published }

    let!(:current_alert) { create(:alert, :published) }

    before do
      create(:alert, :past)
      create(:alert, :future)
      create(:alert) # Draft
    end

    it 'returns all published alerts' do
      expect(published.pluck(:id)).to contain_exactly(current_alert.id)
    end
  end
end
