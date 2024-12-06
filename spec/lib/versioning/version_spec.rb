# frozen_string_literal: true

require 'spec_helper'

describe Versioning::Version do
  context 'without expiry date' do
    subject(:version) { Versioning::Version.new(version_number) }

    let(:version_number) { '2.1' }

    context 'without expiry date' do
      it 'is not expired' do
        expect(version.expired?).to be false
      end

      it 'does not expire' do
        expect(version.expires?).to be false
      end

      it 'finds the most compatible version' do
        expect(version.compatible?('2.0')).to be true
        expect(version.compatible?('2.1')).to be true
        expect(version.compatible?('2.3.8')).to be true
        expect(version.compatible?('1.12')).to be false
        expect(version.compatible?('3.0')).to be false
      end
    end
  end

  context 'with expiry date' do
    subject(:version) { Versioning::Version.new(version_number, expire_on: expiry_date) }

    let(:version_number) { '1.0' }

    context 'in the future' do
      let(:expiry_date) { 5.days.from_now }

      it 'has not yet expired but will expire' do
        expect(version.expired?).to be false
        expect(version.expires?).to be true
      end
    end

    context 'in the past' do
      let(:expiry_date) { 5.days.ago }

      it 'has already expired' do
        expect(version.expired?).to be true
        expect(version.expires?).to be true
      end
    end
  end
end
