# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::Endpoint::Relationships::Relationship do
  subject(:relationship) { described_class.new(name) }

  let(:name) { 'foo' }

  describe '#name' do
    subject { relationship.name }

    it { is_expected.to eq name }
  end

  describe '#includable?' do
    subject { relationship.includable? }

    context 'by default' do
      it { is_expected.to be false }
    end

    context 'when inclusion is allowed explicitly' do
      before { relationship.includable = true }

      it { is_expected.to be true }
    end
  end

  describe '#include?' do
    subject { relationship.include? }

    context 'by default' do
      it { is_expected.to be false }
    end

    context 'when inclusion is allowed explicitly' do
      before { relationship.includable = true }

      it { is_expected.to be false }
    end
  end
end
