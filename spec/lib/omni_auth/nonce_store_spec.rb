# frozen_string_literal: true

require 'spec_helper'

describe OmniAuth::NonceStore do
  let(:nonce) { SecureRandom.urlsafe_base64 }
  let(:value) { 'value' }
  let(:cache) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    stub_const('OmniAuth::NonceStore::MAXIMUM_AGE', 1)
    allow(SecureRandom).to receive(:urlsafe_base64).and_return(nonce)
    allow(Rails).to receive(:cache).and_return(cache)
  end

  describe '.add' do
    it 'stores a nonce in the cache' do
      described_class.add(value)
      expect(described_class.pop(nonce)).to eq(value)
    end

    it 'returns the nonce' do
      expect(described_class.add(value)).to eq(nonce)
    end
  end

  describe '.delete' do
    it 'deletes a nonce from the cache' do
      described_class.add(value)
      described_class.delete(nonce)
      expect(described_class.pop(nonce)).to be_nil
    end
  end

  describe '.read' do
    it 'returns the value for present nonce' do
      described_class.add(value)
      expect(described_class.read(nonce)).to eq value
    end

    it 'returns nil for expired nonce' do
      described_class.add(value)
      expect(described_class.read(nonce)).to eq value
      sleep(OmniAuth::NonceStore::MAXIMUM_AGE)
      expect(described_class.read(nonce)).to be_nil
    end

    it 'returns nil for absent nonce' do
      expect(described_class.read(nonce)).to be_nil
    end

    it 'returns nil for deleted nonce' do
      described_class.add(value)
      expect(described_class.read(nonce)).to eq value
      described_class.delete(nonce)
      expect(described_class.read(nonce)).to be_nil
    end
  end

  describe '.pop' do
    it 'returns the value for present nonce' do
      described_class.add(value)
      expect(described_class.pop(nonce)).to eq value
    end

    it 'returns nil for expired nonce' do
      described_class.add(value)
      expect(described_class.pop(nonce)).to eq value
      sleep(OmniAuth::NonceStore::MAXIMUM_AGE)
      expect(described_class.pop(nonce)).to be_nil
    end

    it 'returns nil for absent nonce' do
      expect(described_class.pop(nonce)).to be_nil
    end

    it 'deletes the nonce' do
      described_class.add(value)
      expect(described_class.pop(nonce)).to eq value
      expect(described_class.pop(nonce)).to be_nil
    end
  end
end
