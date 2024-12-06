# frozen_string_literal: true

require 'spec_helper'

describe Versioning::Negotiation do
  subject(:negotiation) { Versioning::Negotiation.new(supported_versions) }

  let(:current_version) { Versioning::Version.new('2.1') }
  let(:old_version) { Versioning::Version.new('1.5', expire_on: 5.days.from_now) }
  let(:expired_version) { Versioning::Version.new('0.5', expire_on: 5.days.ago) }

  context 'with just the current version' do
    let(:supported_versions) { [current_version] }

    it 'sets current version to first item of supported versions' do
      expect(negotiation.current_version).to eq current_version
    end

    it 'assigns current version with blank requested version' do
      expect(negotiation.assign_version('')).to eq current_version
    end

    it 'returns compatible version to requested version' do
      expect(negotiation.assign_version('2.1')).to eq current_version
    end
  end

  context 'with current and old versions' do
    let(:supported_versions) { [current_version, old_version] }

    it 'assigns the most compatible version to requested version' do
      expect(negotiation.assign_version('1.5')).to eq old_version
      expect(negotiation.assign_version('2.0')).to eq current_version
    end
  end

  context 'with an expired version' do
    let(:supported_versions) { [current_version, old_version, expired_version] }

    it 'does not assign a version' do
      expect(negotiation.assign_version('0.5')).to be_nil
    end
  end

  context 'with an expired version with same major of requested' do
    let(:expired_version) { Versioning::Version.new('1.0', expire_on: 5.days.ago) }
    let(:supported_versions) { [current_version, old_version, expired_version] }

    it 'assigns not expired version with same major' do
      expect(negotiation.assign_version('1.0')).to eq old_version
    end
  end
end
