# frozen_string_literal: true

require 'spec_helper'

describe Home::ChannelPresenter, type: :presenter do
  subject(:channel_presenter) { described_class.new(channel) }

  let(:channel_description) { {en: 'Test description', de: 'Testbeschreibung'} }
  let(:channel) { build(:channel, description: channel_description) }

  describe '#description' do
    it 'defaults to English' do
      expect(channel_presenter.description).to eq 'Test description'
    end

    context 'without description' do
      let(:channel_description) { {} }

      it 'is empty' do
        expect(channel_presenter.description).to be_empty
      end
    end
  end
end
