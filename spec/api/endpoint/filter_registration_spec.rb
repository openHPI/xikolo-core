# frozen_string_literal: true

require 'spec_helper'

describe Xikolo::Endpoint::FilterRegistration do
  subject(:definition) { described_class.new }

  describe '#determine_from' do
    subject(:result) { definition.determine_from(filter_hash) }

    let(:filter_hash) { {} }

    describe 'required filter' do
      let(:required_opts) { {} }

      before do
        definition.from { required 'must' }
      end

      context 'missing' do
        it { expect { result }.to raise_error Xikolo::Endpoint::Filter::InvalidFilter }
      end

      context 'with another key' do
        let(:filter_hash) { {'another' => 'value'} }

        it { expect { result }.to raise_error Xikolo::Endpoint::Filter::InvalidFilter }
      end

      context 'provided' do
        let(:filter_hash) { {'must' => 'value'} }

        it { is_expected.to be_a Hash }
        it { is_expected.to eq filter_hash }
      end
    end

    describe 'optional filter' do
      before do
        definition.from { optional 'can' }
      end

      context 'missing' do
        it { is_expected.to be_a Hash }
        it { is_expected.not_to have_key 'can' }
      end

      context 'with another key' do
        let(:filter_hash) { {'another' => 'value'} }

        it { is_expected.to be_a Hash }
        it { is_expected.not_to have_key 'can' }
      end

      context 'provided' do
        let(:filter_hash) { {'can' => 'value'} }

        it { is_expected.to be_a Hash }
        it { is_expected.to have_key 'can' }
      end
    end
  end
end
