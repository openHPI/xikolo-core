# frozen_string_literal: true

require 'spec_helper'

describe Course::Channel, '.by_identifier', type: :model do
  subject(:scope) { described_class.by_identifier(param) }

  let(:channel) { create(:channel, code: 'great-channel') }

  context 'when params corresponds to channel code' do
    let(:param) { 'great-channel' }

    it 'returns an array of one channel with same code' do
      expect(scope).to eq [channel]
    end
  end

  context 'when params corresponds to channel id' do
    let(:param) { channel.id }

    it 'returns an array of one channel with same id' do
      expect(scope).to eq [channel]
    end
  end

  context 'when params does not correspond neither to channel code or id' do
    let(:param) { 'banana' }

    it 'returns an empty array' do
      expect(scope).to eq []
    end
  end
end
