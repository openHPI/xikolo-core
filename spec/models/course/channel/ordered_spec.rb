# frozen_string_literal: true

require 'spec_helper'

describe Course::Channel, '.ordered', type: :model do
  subject(:scope) { described_class.ordered }

  let(:channel_1) { create(:channel, code: 'zebra', position: 1, name: 'Channel 1') }
  let(:channel_2) { create(:channel, code: 'bunny', position: 2, name: 'Channel 2') }
  let(:channel_3) { create(:channel, code: 'apple', position: 3, name: 'Channel 3') }

  context 'with multiple channels, where the postion is set' do
    it 'returns channels ordered by position' do
      expect(scope).to contain_exactly(channel_1, channel_2, channel_3)
    end
  end

  context 'with channels where the position is set to nil' do
    before do
      channel_1.update_attribute(:position, nil)
      channel_2.update_attribute(:position, nil)
      channel_3.update_attribute(:position, nil)
    end

    it 'returns channels ordered by code, alphabetically' do
      expect(scope).to contain_exactly(channel_3, channel_2, channel_1)
    end
  end

  context 'with channels where the position is set and some where it is not set' do
    let(:channel_4) { create(:channel, code: 'cake', position: nil, name: 'Channel 4') }

    before { channel_3.update_attribute(:position, nil) }

    it 'returns channels ordered by position and by code last' do
      expect(scope).to contain_exactly(channel_1, channel_2, channel_3, channel_4)
    end
  end
end
